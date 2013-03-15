rm(list=ls())
library(DESeq)
library(matrixStats)
library(reshape)
library(ggplot2)
library(preprocessCore)
source(file.path(Sys.getenv('MAYAROOT'), 'src/rscripts/utils/sample.info.r'))
source('/media/fusion10/work/sofiakp/scott/rfiles/plot.heatmap.R')
source(file.path(Sys.getenv('MAYAROOT'), 'src/rscripts/utils/deseq.utils.r'))
source(file.path(Sys.getenv('MAYAROOT'), 'src/rscripts/isva/isvaFn.R'))
source(file.path(Sys.getenv('MAYAROOT'), 'src/rscripts/isva/DoISVA.R'))
source(file.path(Sys.getenv('MAYAROOT'), 'src/rscripts/isva/EstDimRMT.R'))

set.seed(1)

# Clustering and visualization of signal in regions (exons, peak regions etc)

#counts.dir = file.path(Sys.getenv('MAYAROOT'), 'rawdata/segSignal/14indiv/extractSignal/fc/avgSig/') 
#counts.dir = file.path(Sys.getenv('MAYAROOT'), 'rawdata/genomeGrid/hg19_w10k/combrep/fc/avgSig/') 
#counts.dir = file.path(Sys.getenv('MAYAROOT'), 'rawdata/transcriptomes/combrep/extractSignal/fc/avgSig/')
counts.dir = file.path(Sys.getenv('MAYAROOT'), 'rawdata/signal/mergedInputs/combrep/extractSignal/fc/avgSig/')
#counts.dir = '../../rawdata/dhs/alan/combrep/extractSignal/fc/avgSig/'
#counts.dir= file.path(Sys.getenv('MAYAROOT'), 'rawdata/geneCounts/rdata/repsComb/')
#deseq.dir = file.path(counts.dir, 'deseq/')
########### CHANGE THIS !!!!!!!!!!!!!!!!!!!!!
outpref = 'SNYDER_HG19_all_reg_' 
#outpref = 'gencode.v13.annotation.noM.genes_all_reg_'
#outpref = 'txStates_10_11_12_'
#outpref = 'hg19_w10k_all_reg_'
#outpref = 'all_reg_'
#outpref = 'pritchard_dhs_200bp_left_'

plotdir = file.path(counts.dir, 'plots', 'qn_isvaNull_fits_all_reg')
outdir = file.path(counts.dir, 'rdata') # Set to null if you don't want to write the merged data to a file
if(!file.exists(plotdir)) dir.create(plotdir, recursive=T)
if(!file.exists(outdir)) dir.create(outdir)
counts.dir = file.path(counts.dir, 'textFiles')
k = 6
is.genes = F # T for RZ data
plot.only = F
quant = 0.4 # 0.4 for peak regions and transcriptomes
mark = 'H3K27AC'

if(!plot.only){
  if(is.genes){
    load('../../rawdata/transcriptomes/gencode.v13.annotation.noM.genes.RData')
    indivs = unique(as.character(sample.info(list.files(counts.dir, pattern = 'SNYDER_HG19_.*RZ_0.RData'), '.RData')$indiv))
    nindivs = length(indivs)
    counts.dat = avg.counts(counts.dir, indivs, paste(mark, '_0.RData', sep = ''), meta = gene.meta, len.norm = F)
    regions = counts.dat$regions
    counts = asinh(counts.dat$counts) 
  }else{
    ############ Do this if you're using average signal (eg FC) in regions
    # region.file: BED file with regions to read. 
    # signal.files: should be txt files with just one column of values with the signal in each of the regions in region.file
    
    region.file = file.path(Sys.getenv('MAYAROOT'), 'rawdata/signal/mergedInputs/combrep/peakFiles/merged/', paste('SNYDER_HG19', mark, 'merged.bed.gz', sep = '_'))
    #region.file = paste('../../rawdata/signal/combrep/peakFiles/merged/rand/SNYDER_HG19', mark, 'merged_rand.bed.gz', sep = '_')
    #region.file = file.path(Sys.getenv('MAYAROOT'), 'rawdata/genomeGrid/hg19_w10k.bed')
    #region.file = '../../rawdata/transcriptomes/gencode.v13.annotation.noM.genes.bed'
    #region.file = '../../rawdata/segSignal/14indiv/txStates_10_11_12.bed'
    #region.file = '../../rawdata/dhs/alan/pritchard_dhs_200bp_left.bed'
    signal.files = list.files(counts.dir, pattern = paste(gsub('.bed|.bed.gz', '', basename(region.file)), '_AT_SNYDER_HG19_.*', mark, '.*.txt', sep = ''), full.names = T)
    indivs = unique(gsub(paste('.*_AT_SNYDER_HG19_|_', mark, '.*.txt', sep = ''), '', basename(signal.files)))
    non.san = get.pop(indivs) != 'San' & indivs != 'GM19193'
    indivs = indivs[non.san]
    nindivs = length(indivs)
    counts.dat = load.avg.sig.data(region.file, signal.files[non.san], indivs) 
    regions = counts.dat$regions
    counts = asinh(counts.dat$signal) 
    if(basename(region.file) == 'gencode.v13.annotation.noM.genes.bed'){
      tmp = read.table(region.file, header = F, stringsAsFactors = T, sep = '\t')
      load('../../rawdata/transcriptomes/gencode.v13.annotation.noM.genes.RData')
      match.id = match(tmp[, 4], rownames(gene.meta)) # remove genes not in the annotations
      regions = regions[!is.na(match.id), ]
      counts = counts[!is.na(match.id), ]
      regions$gene.name = gene.meta$gene.name[match.id[!is.na(match.id)]]
      regions = regions[order(match.id[!is.na(match.id)]), ] # Put in the same order as the annotation
      counts = counts[order(match.id[!is.na(match.id)]), ]
    }
  }
  indivs[indivs == 'SNYDER'] = 'MS1'
  # counts = log2(counts$datsignal + 1) # For MAnorm
  
  ############# Quantile normalization
  counts = normalize.quantiles(counts)
  colnames(counts) = indivs 
  
  # Remove rows with low variance or NaNs
  good.rows = apply(counts, 1, function(x) !any(is.na(x)))
  counts = counts[good.rows, ]
  regions = regions[good.rows, ]
  row.means = rowMeans(counts)
  row.sds = rowSds(counts)
  cvs = row.sds / row.means
  ################## Increase this minimum cutoff if you're using non-enriched regions
  good.rows = !is.na(cvs) & row.means > asinh(0.2) & cvs > quantile(cvs, quant, na.rm = T)
  if(!is.null(outdir)) save(regions, counts, good.rows, file = file.path(outdir, paste(outpref, mark, '_qn.RData', sep = '')))
  counts = counts[good.rows, ]
  counts.norm = scale(counts) #apply(counts, 2, function(x) (x - row.means[good.rows])/row.sds[good.rows])
  regions = regions[good.rows, ]
  
  ############### ISVA correction to remove batch effects
  pop = factor(get.pop(indivs))
  isva.fit = DoISVA(counts.norm, pop, pvth = 0.05, th = 0.05, ncomp = 2) # th = 0.05, ncomp = 2) for peaks and transcriptomes
  
  ############### Do PCA on the "un-corrected" data and plot eigenvalues
  counts.no.child = counts.norm[, !(indivs %in% c('GM12878', 'GM19240'))]
  pca.fit = prcomp(t(counts.no.child), center = F, scale = F)
  p.dat = plot.pcs(t(counts.norm) %*% pca.fit$rotation,  pca.fit$rotation, pca.fit$sdev, labels = colnames(counts), groups = get.pop(colnames(counts)), all = T)
  ggsave(file.path(plotdir, paste(outpref, 'pca_preIsva_', mark, '.pdf', sep = '')), p.dat$p1, width = 9, height = 6.8)
  ggsave(file.path(plotdir, paste(outpref, 'eigen_', mark, '.pdf', sep = '')), p.dat$p2, width = 6.5, height = 5.6)
  
  counts = normalize.quantiles(isva.fit$res.null) # Get residuals after removing ISVs and renormalize
  colnames(counts) = indivs
  counts.norm = scale(counts)
  if(!is.null(outdir)) save(regions, counts, isva.fit, file = file.path(outdir, paste(outpref, mark, '_qn_isvaNull.RData', sep = ''))) 
  
  sel = isva.fit$deg # Regions significantly correlated with population
  # Write the significant regions
  oldsc = options(scipen = 100) # prevent scientific notation in output
  outfile = file.path(plotdir, paste(outpref, 'isva_sign_', mark, '.txt', sep = ''))
  if(is.null(regions$gene.name)){
    names = data.frame(chr = regions$chr[sel], start = regions$start[sel] - 1, end = regions$end[sel])
  }else{
    names = regions$gene.name[sel]
  }
  write.table(names, file = outfile, quote = F, row.names = F, col.names = F, sep = "\t")
  options(oldsc)
  
  # Plot ISVs
  isv.dat = data.frame(isva.fit$isv)
  colnames(isv.dat) = paste('ISV', 1:ncol(isv.dat))
  isv.dat$indiv = factor(indivs)
  isv.dat = melt(isv.dat, id.vars=c('indiv'))
  p = ggplot(isv.dat) + geom_bar(aes(x = indiv, y = value), position = 'dodge', stat = 'identity') + facet_wrap(~variable) +
    xlab('') + ylab('ISV value') + 
    theme(strip.text.x = element_text(size = 16), axis.text.y = element_text(size = 14), axis.title.y = element_text(size = 16),
          axis.text.x = element_text(size = 14, angle = -45, vjust = 1, hjust = 0))
  ggsave(file.path(plotdir, paste(outpref, 'isvs_', mark, '.pdf', sep = '')), p, width = 9, height = 6.8)
}else{
  load(file.path(outdir, paste(outpref, mark, '_qn_isvaNull.RData', sep = '')))
  indivs = colnames(counts)
  nindivs = length(indivs)
  counts.norm = scale(counts, center = T, scale = T)  
}
indivs[indivs == 'SNYDER'] = 'MS1'
colnames(counts)[colnames(counts) == 'SNYDER'] = 'MS1'
colnames(counts.norm)[colnames(counts.norm) == 'SNYDER'] = 'MS1'

############### FINAL PLOTTING - Can do it by reloading the SVA corrected data
no.child.cols = !(indivs %in% c('GM12878', 'GM19240'))
sel = isva.fit$deg

# pca.indiv = prcomp(counts, center = F, scale = F)
# pcs = c(1)
# pc.counts = counts
# for(i in 1:dim(counts)[1]){
#   d = data.frame(y = counts[i, ])
#   model = 'y ~ '
#   for(j in pcs){
#     d[[paste('x', j, sep = '')]] = pca.indiv$rotation[, j]
#     if(j == pcs[1]){ model = paste(model, ' ', 'x', j, sep = '')
#     }else{model = paste(model, ' + ', 'x', j, sep = '')}
#   }
#   pc.counts[i, ] = lm(model, data = d)$residuals
# }
# counts = normalize.quantiles(pc.counts)
# colnames(counts) = indivs

############### Pairwise correlations between individuals
corr.mat = array(1, dim = c(nindivs, nindivs))
for(i in 1:(nindivs - 1)){
  for(j in (i + 1):nindivs){
    corr.mat[i, j] = cor(counts.norm[, i], counts.norm[,j], use = 'pairwise.complete.obs', method = 'pearson')
    corr.mat[j, i] = corr.mat[i, j]
  }
}
plot.heatmap(corr.mat, filt.thresh = NA, symm.cluster = T, lab.row = indivs, lab.col = indivs, row.title= '', col.title = '', cex.row = 1.5, cex.col = 1.5,
             dist.metric='spearman', clust.method = "average", break.type='linear', palette = brewer.pal(9, 'Reds'), ColSideColors = get.pop.col(get.pop(indivs)),
             RowSideColors = get.pop.col(get.pop(indivs)), keysize = 1,
             to.file = file.path(plotdir, paste(outpref, 'corrMat_', mark, '.pdf', sep = '')))

############### PCA
# Rows are observations (cells), columns are variables
# Remove daughters before PCA, but then project them too on the new dimensions
counts.no.child = counts.norm[, no.child.cols]
pca.fit = prcomp(t(counts.no.child), center = F, scale = F)
p=plot.pcs(t(counts.norm) %*% pca.fit$rotation,  pca.fit$rotation, pca.fit$sdev, labels = indivs, groups = get.pop(indivs), all = T)
ggsave(file.path(plotdir, paste(outpref, 'pca_', mark, '.pdf', sep = '')), p$p1, width = 9, height = 6.8)

# Write the genes or regions with the largest loadings for enrichment analysis
# sel = order(pca.fit$rotation[, 1])[1:1000]
# outfile = file.path(plotdir, paste('pca_', mark, '.txt', sep = ''))
# if(is.null(meta)){
#   names = data.frame(chr = regions$chr[sel], start = regions$start[sel] - 1, end = regions$end[sel])
# }else{
#   names = meta$gene.name[sel]
# }
# write.table(names, file = outfile, quote = F, row.names = F, col.names = F, sep = "\t")

############### Kmeans
if(isva.fit$ndeg > 10){
  kclusters = kmeans(counts.norm[isva.fit$deg, ], centers = k, iter.max = 500, nstart = 10)
  kord = heatmap.2(scale(kclusters$centers))$rowInd
  
  oldsc = options(scipen = 100)
  sel.rows = c()
  row.sep = c()
  for(i in 1:k){
    sel = which(kclusters$cluster == kord[i])
    outfile = file.path(plotdir, paste(outpref, 'isva_', mark, '_k',k, '_clust', kord[i], '.txt', sep = ''))
    if(is.null(regions$gene.name)){
      names = data.frame(chr = regions$chr, start = regions$start - 1, end = regions$end)[isva.fit$deg[sel], ]
    }else{
      names = regions$gene.name[isva.fit$deg][sel]
    }
    write.table(names, file = outfile, quote = F, row.names = F, col.names = F, sep = "\t")
    cluster.frac = length(sel) / length(isva.fit$deg) # fraction of regions belonging in the cluster
    sel.rows = append(sel.rows, sel[sample(1:length(sel), min(length(sel), round(5000 * cluster.frac)))]) # Sample the cluster proportionally to its size
    row.sep = append(row.sep, length(sel.rows))
  }
  options(oldsc)
  #idx = sort(kclusters$cluster[sel.rows], index.return = T) # Sort by cluster idx
  #sel.rows = isva.fit$deg[sel.rows][idx$ix]
  h = plot.heatmap(counts.norm[isva.fit$deg[sel.rows], ], row.cluster = F, col.cluster = T, show.dendro = "none", row.title= '', col.title = '', lab.row = NA, dist.metric = "euclidean", clust.method = "ward", 
               break.type='quantile', filt.thresh = NA, replace.na = F, palette = brewer.pal(9,  "RdYlBu")[seq(9,1,-1)], ColSideColors = get.pop.col(get.pop(indivs)), 
               RowSideColors = rep('white', length(sel.rows)), cex.col = 2, row.sep = row.sep, keysize = 1,
               to.file = file.path(plotdir, paste(outpref, 'biclust_', mark, '_k', k, '.pdf', sep = '')))
  plot.rows = sel.rows
  plot.cols = h$colInd
  save(kclusters, kord, plot.rows, plot.cols, file = file.path(outdir, paste(outpref, mark, '_qn_isvaNull_clust', k, '.RData', sep = '')))
  
  orig = new.env()
  load(file.path(outdir, paste(outpref, mark, '_qn.RData', sep = '')), orig)

  # First select the rows that participated in ISVA. Then, get the same rows that were used in the above clustering.
  plot.counts = orig$counts[orig$good.rows, plot.cols][isva.fit$deg[sel.rows], ]
  plot.heatmap(scale(plot.counts), row.cluster = F, col.cluster = F, show.dendro = "none", row.title= '', col.title = '', lab.row = NA, lab.col = indivs[plot.cols], dist.metric = "euclidean", clust.method = "ward", 
               break.type='quantile', filt.thresh = NA, replace.na = F, palette = brewer.pal(9,  "RdYlBu")[seq(9,1,-1)], ColSideColors = get.pop.col(get.pop(indivs[plot.cols])), 
               RowSideColors = rep('white', length(sel.rows)), cex.col = 2, row.sep = row.sep, keysize = 1,
               to.file = file.path(plotdir, paste(outpref, 'biclust_preIsva_', mark, '_k', k, '.pdf', sep = '')))
}

########### Do this if you're using gene/peakcounts
# diff = get.diff.count(list.files(deseq.dir, pattern = paste('.*', mark, '_deseq.RData', sep = ''),  full.names = T), 1e-10) > 10
# indivs = unique(as.character(sample.info(list.files(counts.dir, pattern = paste('SNYDER_HG19_.*', mark, '_0.RData', sep = '')), '.RData')$indiv))
# counts.dat = avg.counts(counts.dir, indivs, paste(mark, '_0.RData', sep = ''), meta = meta) 
# regions = counts.dat$regions[diff, ]
# counts = counts.dat$counts[diff, ]
# meta = meta[diff, ]

############ Do this if you're using signal at dips
# dip.file = file.path(Sys.getenv('MAYAROOT'), 'rawdata/signal/combrep/dips/llr/bed/SNYDER_HG19_H3K27AC_merged_dips.bed')
# dip.count.files = list.files(counts.dir, pattern = 'SNYDER_HG19_H3K27AC_merged_dips_AT_SNYDER_HG19_.*txt', full.names = T)
# indivs = unique(as.character(sample.info(gsub('SNYDER_HG19_H3K27AC_merged_dips_AT_', '', dip.count.files), '.txt')$indiv))
# nindivs = length(indivs)
# counts.dat = load.dip.data(dip.file, dip.count.files, indivs)
# regions = counts.dat$regions
# counts = (counts.dat$left.sig + counts.dat$right.sig) / 2
# sel = apply(counts, 1, function(x) !any(is.na(x)))
# regions = regions[sel, ]
# counts = counts[sel, ]

############ MAnorm correction
# Bed files with individual specific peaks. Fits between different individuals are performed on the common peaks only.
# bed.dir = file.path(Sys.getenv('MAYAROOT'), 'rawdata/signal/combrep/peakFiles')
# bed.files = array('', dim = c(nindivs, 1))
# missing = array(F, dim = c(nindivs, 1))
# for(i in 1:nindivs){
#   tmp.files = list.files(bed.dir, pattern = paste('SNYDER_HG19', indivs[i], mark, 'VS_.*', sep = '_'), full.names = T)
#   if(length(tmp.files) != 1){
#     #missing[i] = T
#     tmp.files = list.files(bed.dir, pattern = paste('SNYDER_HG19', indivs[i], mark, '.*dedup_VS_.*', sep = '_'), full.names = T)
#   }
#   stopifnot(length(tmp.files) == 1)
#   bed.files[i] = tmp.files
# }
# 
# bed.files = bed.files[!missing]
# indivs = indivs[!missing]
# nindivs = length(indivs)
# counts = counts[, !missing]
# fits = fit.norm.counts(counts, bed.files, ref.idx = which(indivs == 'GM12878'), take.log = F)
# counts = fits$lr + rep(fits$avg[, which(indivs == 'GM12878')], nindivs)