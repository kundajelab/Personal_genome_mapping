#!/bin/bash
# ========================================
# Read in arguments and check for errors
# ========================================
if [[ "$#" -lt 3 ]]
    then
    echo "Usage: $(basename $0) <iDir> <pairFile> <oDir> <OPT:genome> <OPT:chrSizes> <OPT:memory> <OPT:preComputedFragLenFile>" >&2
    echo '<iDir>: input directory whose subdirectories contain mapped ChIP and control data' >&2
    echo '<pairFile>: input file containing pairs of ChIP (column 1), control dataset names (column 2) and a composite experiment name (column3)' >&2 
    echo '            Multiple ChIP and control files can be present seperated by ; in Col1 and Col2. They will be merged before passing them to MACS' >&2
    echo '<oDir>: output directory' >&2
    echo '<genome>: (OPTIONAL) genome size. Default: hs' >&2
    echo '<chrSizes>: (OPTIONAL) tag delimited chrName\tsize: Default : $GENOMESIZEDIR/hg19.genome' >&2
    echo '<memory>: (OPTIONAL) memory limit 0 (means default), if non-zero then it represents X GB' >&2
    echo '<preComputedFragLenFile>: (OPTIONAL) File containing estimated fragment length for each dataset. Col1: dataset name [tab] Col2:frag length' >&2		
    exit 1
fi

IDIR=$1
if [[ ! -d "${IDIR}" ]]; then echo "ERROR: Argument <iDir> ${IDIR} does not exist" >&2 ; exit 1; fi

IFILE=$2
if [[ ! -f "${IFILE}" ]]; then echo "ERROR: Argument <pairFile> ${IFILE} does not exist" >&2 ; exit 1; fi

ODIR=$3
if [[ ! -d "${ODIR}" ]]; then echo "ERROR: Argument <oDir> ${ODIR} does not exist" >&2; exit 1; fi

GENOMESIZE='hs'
if [[ "$#" -ge 4 ]]; then GENOMESIZE=$4 ; fi

CHRSIZE="${GENOMESIZEDIR}/hg19.genome"
if [[ "$#" -ge 5 ]]; then CHRSIZE=$5 ; fi
if [[ ! -e "${CHRSIZE}" ]]; then echo "ERROR: Argument <chrSizes> ${CHRSIZE} does not exist" >&2 ; exit 1; fi

MEM=0
if [[ "$#" -ge 6 ]]; then MEM=$6 ; fi
memLimit=$(( MEM * 1024 ))

FRAGLENFILE='NULL'
if [[ "$#" -ge 7 ]]; then FRAGLENFILE=$7 ; fi
if [[ ${FRAGLENFILE} != 'NULL' && ! -f "${FRAGLENFILE}" ]]
then
    echo "ERROR: Argument <iSizeFile> ${FRAGLENFILE} does not exist" >&2
    exit 1
fi

# Check if you can call Rscript
if [[ -z $(which macs2) ]]; then echo 'ERROR: MACS executable not in $PATH' >&2; exit 1; fi

# Maximum number of jobs to run at a time
JOBGRPID="/histVarSignal${RANDOM}"

# ========================================
# Read pairFile line by line
# Create shell script
# Submit to cluster
# ========================================

while read inputline
  do
    echo $inputline
    # -------------------------
  # Operate on ChIP files
  # -------------------------
    chip=$(echo ${inputline} | awk '{print $1}' | sed -r 's/\.bam/.bed.gz/g') # extract first column as ChIP file name, replace .bam with .bed.gz
    if echo ${chip} | grep -q ';'; then
	chipstub=$(echo ${inputline} | awk '{print $3}') # If multiple chip files then use column 3 in file as ChIPstub
    else
	chipstub=$(echo ${chip} | sed -r 's/\.bed\.gz//g') # If one chip file then use remove .bed.gz from the file name and use that as ChIPstub
    fi

  # --------------------------
  # Operate on controls
  # --------------------------
    control=$(echo ${inputline} | awk '{print $2}' | sed -r 's/\.bam/.bed.gz/g') # extract second column as control file name, replace .bam with .bed.gz
    controlstub=$(echo ${control} | sed -r -e 's/;.*$//g' -e 's/\.bed\.gz//g') # Use first file name if multiple separated by ; and remove the .bed.gz extension to generate controlstub
 
  # ----------------------
  # Set Output file names
  # ----------------------
    outFile="${ODIR}/${chipstub}_VS_${controlstub}.out"
    errFile="${ODIR}/${chipstub}_VS_${controlstub}.err"
    peakFile="${ODIR}/${chipstub}_VS_${controlstub}"
    fcFile="${peakFile}.fc.signal.bedgraph.gz"
    llrFile="${peakFile}.llr.signal.bedgraph.gz"

    nchip=$(echo ${chip} | sed -r 's/;/\n/g' | wc -l) # number of chip files
    chip=$(echo ${chip} | sed -r 's/;/\n/g' | sort | xargs -I fname find "${IDIR}" -name fname -printf "%p ") # separate file names with space
    if [[ -e ${outFile} || -e ${fcFile} || -e ${llrFile} ]]; then
	echo "Skipping ${peakFile}" >&2
	continue
    fi
  # -------------------------
  # Search for full file path in IDIR
  # ; are replaced by <space>
  # -------------------------
  nchipfound=$(echo ${chip} | sed -r 's/ /\n/g' | wc -l) # number of chip files that were found in IDIR
  if [[ ${nchipfound} -ne ${nchip} ]]; then echo "ERROR: Some of the ChIP files ${chip} were not found in $IDIR" >&2 ; continue ; fi
  
  ncontrol=$(echo ${control} | sed -r 's/;/\n/g' | wc -l) # number of control files
  control=$(echo "${control}" | sed -r 's/;/\n/g' | xargs -I fname find "${IDIR}" -name fname -printf "%p ") # separate file names with space
  ncontrolfound=$(echo ${control} | sed -r 's/ /\n/g' | wc -l) # number of control files that were found in IDIR
  if [[ ${ncontrolfound} -ne ${ncontrol} ]]; then echo "ERROR: Some of the control files ${control} were not found in $IDIR" >&2 ; continue ; fi
  
  # --------------------------
  # Get fragLens corresponding to ChIP files
  # --------------------------
  fraglen=0
  fcount=0
  if [[ ${FRAGLENFILE} != 'NULL' ]]
  then
      for currFile in $(echo ${chip})
      do
	  currBase=$(echo $(basename ${currFile} | sed -r 's/\.bed\.gz/\\./g'))
	  if grep -q ${currBase} ${FRAGLENFILE}
	  then
	      currFragLen=$(grep ${currBase} ${FRAGLENFILE} | awk '{print $2}')
	      fraglen=$((fraglen + currFragLen))
	      fcount=$((fcount + 1))
	  else
	      echo "WARNING: No fragment length found corresponding to file ${currFile}" >&2
	  fi
      done
      [[ ${fcount} -eq 0 ]] && fcount=1
      fraglen=$((fraglen / (2 * fcount))) # Divide by 2 since MACS expects shift-size which is 1/2 fragment length
      if [[ ${fraglen} -eq 0 ]]
      then
	  echo "ERROR: Fragment length is 0 due to missing file names in ${FRAGLENFILE}" >&2
	  continue
      fi
  fi
  
  # -------------------------
  # Initialize submit script
  # -------------------------
  if [[ $(bjobs -g "${JOBGRPID}" 2> /dev/null | wc -l) -gt 30 ]]
      then
      sleep 30s
  fi

  scriptName="temp${RANDOM}${RANDOM}.sh" # script name
  echo '#!/bin/bash' > ${scriptName}
  echo 'tmpdir="${TMP}/tmp${RANDOM}_${RANDOM}"' >> ${scriptName}
  echo 'mkdir ${tmpdir}' >> ${scriptName}
  
  # -------------------------
  # Create temp copies of ChIP and control
  # gunzip and concatenate multiple files if necessary
  # -------------------------	
  echo 'combchip="${tmpdir}/'"${chipstub}"'"' >> ${scriptName}
  echo 'if [[ -f "${combchip}" ]]; then rm -rf "${combchip}"; fi' >> ${scriptName}
  echo "echo Combining ChIP replicates: ${chip}" >> ${scriptName}
  echo "zcat ${chip} | awk 'BEGIN{OFS="'"\t"}{$4="N";$5="1000";print $0}'"'"' >> "${combchip}"' >> ${scriptName}
  
  echo 'combcontrol="${tmpdir}/'"${controlstub}"'"' >> ${scriptName}
  echo 'if [[ -f "${combcontrol}" ]]; then rm -rf "${combcontrol}"; fi' >> ${scriptName}
  echo "echo Combining Control replicates: ${control}" >> ${scriptName}
  echo "zcat ${control} | awk 'BEGIN{OFS="'"\t"}{$4="N";$5="1000";print $0}'"'"' >> "${combcontrol}"' >> ${scriptName}

  # -------------------------
  # Complete script
  # -------------------------
  if [[ ${FRAGLENFILE} == 'NULL' || ${fraglen} -eq 0 ]]
  then
      #echo 'macs2 callpeak -t "${combchip}" -c "${combcontrol}" -f BED'" -n ${peakFile} -g ${GENOMESIZE} -p 1e-2 -m 5,30 -B --SPMR" >> ${scriptName}
      echo 'macs2 callpeak -t "${combchip}" -c "${combcontrol}" -f BED'" -n ${peakFile} -g ${GENOMESIZE} -p 1e-2 --nomodel --shiftsize 73 -B --SPMR" >> ${scriptName}
  else
      echo 'macs2 callpeak -t "${combchip}" -c "${combcontrol}" -f BED'" -n ${peakFile} -g ${GENOMESIZE} -p 1e-2 --nomodel --shiftsize ${fraglen} -B --SPMR" >> ${scriptName}
  fi
  echo 'rm -rf ${tmpdir}' >> ${scriptName}
  echo "rm -f ${peakFile}_peaks.xls ${peakFile}_peaks.bed ${peakFile}_summits.bed" >> ${scriptName}  
  # foldchange bedgraph
  if [[ ! -e ${fcFile} ]]
  then
      echo "macs2 bdgcmp -t ${peakFile}_treat_pileup.bdg -c ${peakFile}_control_lambda.bdg -o ${peakFile}.fc.bedgraph -m FE" >> ${scriptName}
      echo "slopBed -i ${peakFile}.fc.bedgraph -g ${CHRSIZE} -b 0 | gzip -c > ${peakFile}.fc.signal.bedgraph.gz" >> ${scriptName}
      echo "rm -f ${peakFile}.fc.bedgraph" >> ${scriptName}
  fi
  # LLR bedgraph
  if [[ ! -e ${llrFile} ]]
  then
      echo "macs2 bdgcmp -t ${peakFile}_treat_pileup.bdg -c ${peakFile}_control_lambda.bdg -o ${peakFile}.llr.bedgraph -p 0.0001 -m logLR" >> ${scriptName}
      echo "slopBed -i ${peakFile}.llr.bedgraph -g ${CHRSIZE} -b 0 | gzip -c > ${peakFile}.llr.signal.bedgraph.gz" >> ${scriptName}
      echo "rm -rf ${peakFile}.llr.bedgraph" >> ${scriptName}
  fi
  echo "rm -f ${peakFile}_treat_pileup.bdg ${peakFile}_control_lambda.bdg" >> ${scriptName}
      
  # -------------------------
  # Submit script
  # -------------------------
  chmod 755 ${scriptName}
  cp ${scriptName} ${outFile}
  echo '======================================================================' >> ${outFile}
  if [[ ${MEM} -eq 0 ]]
	then
      bsub -q research-rh6 -g "${JOBGRPID}" -J "${chipstub}" -W 24:00 -o ${outFile} -e ${errFile} < ${scriptName}
  else
      bsub -q research-rh6 -g "${JOBGRPID}" -J "${chipstub}" -W 24:00 -M "${memLimit}" -R "rusage[mem=${memLimit}]" -o ${outFile} -e ${errFile} < ${scriptName}
  fi
  
  # -------------------------
  # Delete temporary script
  # -------------------------	
  rm "${scriptName}"
  sleep 1s
done < "${IFILE}"
