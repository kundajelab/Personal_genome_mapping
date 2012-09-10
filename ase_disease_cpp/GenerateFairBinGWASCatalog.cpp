#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <set>
#include <map>
#include <boost/algorithm/string.hpp>
#include <math.h>

using namespace std;
using namespace boost;

namespace generateFairBinGWASCatalog
{
    struct castTSS
    {
        vector<unsigned long> TSS;
        void construct(string &chrNum);
        unsigned long calculateDistance(unsigned long &pos);
    };
    
    int computeBinNum(double &floatAllelFreq, unsigned long distance, bool &illumina, bool &affymetrix);
    
    void castTSS::construct(string &chrNum)
    {
        ifstream infile;
        string prefix = "/home/yulingl/ase_diseases/geneStart/geneStartinChr";
        string fileName;
        fileName = prefix + chrNum;
        infile.open(fileName.c_str());
        vector<string> info;
        string currentLine;
        while (!getline(infile, currentLine).eof())
        {
            split(info, currentLine, is_any_of("\t"));
            unsigned long pos;
            pos = strtoul(info[2].c_str(), NULL, 0);
            TSS.push_back(pos);
        }
        sort(TSS.begin(), TSS.end());
        infile.close();
    }
    
    unsigned long castTSS::calculateDistance(unsigned long &pos)
    {
        int start = 0, end = TSS.size() - 1;
        if (pos < TSS[start])
        {
            return (TSS[start] - pos);
        }
        if (pos >= TSS[end])
        {
            return (pos - TSS[end]);
        }
        while (start < end - 1)
        {
            int middle = (start + end) / 2;
            if (pos >= TSS[start] && pos < TSS[middle])
            {
                end = middle;
            }
            else
            {
                start = middle;
            }
        }
        if (pos - TSS[start] <= TSS[end] - pos)
        {
            return (pos - TSS[start]);
        }
        else
        {
            return (TSS[end] - pos);
        }
    }
    
    int computeBinNum(double &floatAllelFreq, unsigned long distance, bool &illumina, bool &affymetrix)
    {
        int allelFreqBinNum;
        int logDistanceBinNum;
        int platform;
        
        srand(time(NULL));
        if (floatAllelFreq == 0.5)
        {
            allelFreqBinNum = 4;
        }
        else
        {
            allelFreqBinNum = int(floor(floatAllelFreq / 0.1));
        }
        
        double logDistance = log10(distance);
        if (logDistance <= 3.5)
        {
            logDistanceBinNum = 0;
        }
        else if (logDistance > 6)
        {
            logDistanceBinNum = 26;
        }
        else
        {
            logDistanceBinNum = int(ceil((logDistance - 3.5) / 0.1));
        }
        if (illumina && !affymetrix)
        {
            platform = 0;
        }
        else if (!illumina && affymetrix)
        {
            platform = 1;
        }
        else
        {
            int randNum = abs(rand() % 2);
            platform = randNum;
        }
        return logDistanceBinNum + allelFreqBinNum * 27 + platform * 27 * 5;
    }
    
    struct castLD
    {
        map<string, set<string> > tag_SNPinLD;
        void constructOverChr(string &chrNum, string &population);
    };
    
    void castLD::constructOverChr(string &chrNum, string &population)
    {
        ifstream infile;
        string fileName = "/home/yulingl/ase_diseases/hapmap_ld/" + population + "_0.1/" + chrNum;
        infile.open(fileName.c_str());
        vector<string> info;
        string currentLine;
        while (!getline(infile, currentLine).eof())
        {
            split(info, currentLine, is_any_of("\t"));
            string key1 = chrNum + "_" + info[0];
            string key2 = chrNum + "_" + info[1];
            map<string, set<string> >::iterator pIt1 = tag_SNPinLD.find(key1);
            map<string, set<string> >::iterator pIt2 = tag_SNPinLD.find(key2);
            if (pIt1 == tag_SNPinLD.end())
            {
                set<string> tmp;
                tmp.insert(key1);
                tmp.insert(key2);
                tag_SNPinLD[key1] = tmp;
            }
            else
            {
                tag_SNPinLD[key1].insert(key1);
                tag_SNPinLD[key1].insert(key2);
            }
            if (pIt2 == tag_SNPinLD.end())
            {
                set<string> tmp1;
                tmp1.insert(key1);
                tmp1.insert(key2);
                tag_SNPinLD[key2] = tmp1;
            }
            else
            {
                tag_SNPinLD[key2].insert(key1);
                tag_SNPinLD[key2].insert(key2);
            }
        }
        infile.close();
    }
    
    struct castSNP
    {
        set<string> onChip;
        set<string> onHapMap;
        void construct(string &chrNum, string &population);
    };
    
    void castSNP::construct(string &chrNum, string &population)
    {
        ifstream infile;
        string prefix = "/home/yulingl/ase_diseases/SNPonChips/allSNPonChip/SNPOnChipInChr";
        string fileName = prefix + chrNum;
        infile.open(fileName.c_str());
        string currentLine;
        vector<string> info;
        while (!getline(infile, currentLine).eof())
        {
            split(info, currentLine, is_any_of("\t"));
            string key = chrNum + "_" + info[1];
            onChip.insert(key);
        }
        infile.close();
        
        fileName = "/home/yulingl/ase_diseases/hapmap_ld/" + population + "_SNPSet/" + chrNum;
        infile.open(fileName.c_str());
        while (!getline(infile, currentLine).eof())
        {
            string key = chrNum + "_" + currentLine;
            onHapMap.insert(key);
        }
        infile.close();
    }
    
    struct GWASSNPInfo
    {
        double pvalue;
        bool illumina, affymetrix;
        string function;
        double allelFreq;
        unsigned long coord;
    };
    
    struct castGWAS
    {
        set<string> initial_keys;
        set<string> filteredKeys;
        map<string, GWASSNPInfo> key_info;
        
        map<double, set<string> > pvalue_SNPs;
        map<string, double> SNP_pvalue;
        
        set<string> fairKeys;
        
        void construct(string &chrNum);
        void interSect(castSNP &SNPs);
        
        void constructMap();
        void generateFairSet(castLD &LD);
        
        void output(string &chrNum, castTSS &TSS);
    };
    
    void castGWAS::output(string &chrNum, castTSS &TSS)
    {
        system("mkdir -p /home/yulingl/ase_diseases/gwasCatalog/fairBinedGWASCatalog");
        ofstream outfile;
        string fileName = "/home/yulingl/ase_diseases/gwasCatalog/fairBinedGWASCatalog/" + chrNum;
        outfile.open(fileName.c_str());
        for (set<string>::iterator it = fairKeys.begin(); it != fairKeys.end(); ++ it)
        {
            map<string, GWASSNPInfo>::iterator pIt = key_info.find(*it);
            int binNum = computeBinNum(pIt->second.allelFreq, TSS.calculateDistance(pIt->second.coord), pIt->second.illumina, pIt->second.affymetrix);
            if (binNum < 0 || binNum > 269)
            {
                cout << *it << "\t" << binNum << endl;
            }
            else
            {
                outfile << *it << "\t" << computeBinNum(pIt->second.allelFreq, TSS.calculateDistance(pIt->second.coord), pIt->second.illumina, pIt->second.affymetrix) << endl;
            }
        }
        outfile.close();
    }
    
    void castGWAS::generateFairSet(castLD &LD)
    {
        srand(time(NULL));
        vector<double> pvalue;
        for (map<double, set<string> >::iterator it = pvalue_SNPs.begin(); it != pvalue_SNPs.end(); ++ it)
        {
            pvalue.push_back(it -> first);
        }
        sort(pvalue.begin(), pvalue.end());
        for (vector<double>::reverse_iterator it = pvalue.rbegin(); it != pvalue.rend(); ++ it)
        {
            map<double, set<string> >::iterator searchIt = pvalue_SNPs.find(*it);
            if (searchIt != pvalue_SNPs.end() && searchIt -> second.size() != 0)
            {
                vector<string> vectorForRand;
                for (set<string>::iterator subIt = searchIt->second.begin(); subIt != searchIt->second.end(); ++ subIt)
                {
                    vectorForRand.push_back(*subIt);
                }
                
                map<string, int> SNP_index;
                for (int i = 0; i < vectorForRand.size(); ++ i)
                {
                    SNP_index[vectorForRand[i]] = i;
                }
                int actualSize = vectorForRand.size();
                while (actualSize != 0)
                {
                    if(double(actualSize)/double(vectorForRand.size()) > 0.2)
                    {
                        int randNum;
                        while (true)
                        {
                            randNum = rand() % vectorForRand.size();
                            if (vectorForRand[randNum] != "")
                            {
                                break;
                            }
                        }
                        string SNPtoInsert = vectorForRand[randNum];
                        fairKeys.insert(SNPtoInsert);
                        map<string, set<string> >::iterator subSearchIt = LD.tag_SNPinLD.find(SNPtoInsert);
                        if (subSearchIt != LD.tag_SNPinLD.end())
                        {
                            for (set<string>::iterator subIt = subSearchIt -> second.begin(); subIt != subSearchIt -> second.end(); ++ subIt)
                            {
                                map<string, double>::iterator pItSNP_pvalue = SNP_pvalue.find(*subIt);
                                if (pItSNP_pvalue != SNP_pvalue.end())
                                {
                                    pvalue_SNPs[pItSNP_pvalue->second].erase(*subIt);
                                    SNP_pvalue.erase(*subIt);
                                }
                                
                                map<string, int>::iterator pItSNP_index = SNP_index.find(*subIt);
                                if (pItSNP_index != SNP_index.end())
                                {
                                    vectorForRand[pItSNP_index -> second] = "";
                                    SNP_index.erase(pItSNP_index);
                                    actualSize --;
                                }
                            }
                        }
                        else
                        {
                            vectorForRand[randNum] = "";
                            SNP_index.erase(SNPtoInsert);
                            pvalue_SNPs[SNP_pvalue[SNPtoInsert]].erase(SNPtoInsert);
                            SNP_pvalue.erase(SNPtoInsert);
                            actualSize --;
                        }
                    }
                    else
                    {
                        vector<string> newSNPVector;
                        for (vector<string>::iterator subIt = vectorForRand.begin(); subIt != vectorForRand.end(); subIt ++)
                        {
                            if (*subIt != "")
                            {
                                newSNPVector.push_back(*subIt);
                            }
                        }
                        vectorForRand = newSNPVector;
                        map<string, int> newSNP_index;
                        for (int i = 0; i < vectorForRand.size(); ++ i)
                        {
                            newSNP_index[vectorForRand[i]] = i;
                        }
                        SNP_index.clear();
                        SNP_index = newSNP_index;
                    }
                }
            }
        }
    }
    
    void castGWAS::constructMap()
    {
        for (set<string>::iterator it = filteredKeys.begin(); it != filteredKeys.end(); ++ it)
        {
            if (pvalue_SNPs.find(key_info[*it].pvalue) == pvalue_SNPs.end())
            {
                set<string> tmp;
                tmp.insert(*it);
                pvalue_SNPs[key_info[*it].pvalue] = tmp;
            }
            else
            {
                pvalue_SNPs[key_info[*it].pvalue].insert(*it);
            }
            SNP_pvalue[*it] = key_info[*it].pvalue;
        }
    }
    
    void castGWAS::construct(string &chrNum)
    {
        ifstream infile;
        string fileName = "/home/yulingl/ase_diseases/gwasCatalog/processedGWASCatalog/" + chrNum;
        infile.open(fileName.c_str());
        vector<string> L0Info;
        string currentLine;
        while (!getline(infile, currentLine).eof())
        {
            split(L0Info, currentLine, is_any_of("\t"));
            
            vector<string> L1Info;
            set<string> platformSet;
            split(L1Info, L0Info[5], is_any_of(","));
            for (int i = 0; i < L1Info.size(); ++ i)
            {
                platformSet.insert(L1Info[i]);
            }
            
            if (platformSet.find("Affymetrix") != platformSet.end() || platformSet.find("Illumina") != platformSet.end())
            {
                initial_keys.insert(L0Info[0]);
                
                GWASSNPInfo tmpInfo;
                tmpInfo.allelFreq = atof(L0Info[1].c_str());
                if (tmpInfo.allelFreq > 0.5)
                {
                    tmpInfo.allelFreq = 1 - tmpInfo.allelFreq;
                }
                tmpInfo.coord = strtoul(L0Info[2].c_str(), NULL, 0);
                tmpInfo.pvalue = atof(L0Info[3].c_str());
                tmpInfo.function = L0Info[4];
                if (platformSet.find("Affymetrix") != platformSet.end())
                {
                    tmpInfo.affymetrix = 1;
                }
                else
                {
                    tmpInfo.affymetrix = 0;
                }
                if (platformSet.find("Illumina") != platformSet.end())
                {
                    tmpInfo.illumina = 1;
                }
                else
                {
                    tmpInfo.illumina = 0;
                }
                key_info[L0Info[0]] = tmpInfo;
            }
        }
        infile.close();
    }
    
    void castGWAS::interSect(castSNP &SNPs)
    {
        set<string> tmp;
        
        set_intersection(initial_keys.begin(), initial_keys.end(), SNPs.onChip.begin(), SNPs.onChip.end(), inserter(tmp, tmp.end()));
        filteredKeys.clear();
        set_intersection(tmp.begin(), tmp.end(), SNPs.onHapMap.begin(), SNPs.onHapMap.end(), inserter(filteredKeys, filteredKeys.end()));
    }
}

using namespace generateFairBinGWASCatalog;

int main_generateFairBinGWAS(const vector<string> &all_args)
{
    if (all_args.size() != 3)
    {
        cout << "Usage: ase_disease generateFairBinGWAS population" << endl;
        exit(0);
    }
    
    for (int i = 1; i <= 23; i++)
    {
        string chrNum;
        if (i == 23)
        {
            chrNum = "X";
        }
        else
        {
            stringstream convert;
            convert << i;
            chrNum = convert.str();
        }
        castTSS TSS;
        TSS.construct(chrNum);
        
        string population = all_args[2];
        
        castLD LD;
        LD.constructOverChr(chrNum, population);
        
        castSNP SNP;
        SNP.construct(chrNum, population);
        
        castGWAS GWAS;
        GWAS.construct(chrNum);
        GWAS.interSect(SNP);
        
        GWAS.constructMap();
        GWAS.generateFairSet(LD);
        
        GWAS.output(chrNum, TSS);
    }
    return 0;
}
