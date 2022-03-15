# GWAS 
This repository provides a description of workflow for analysing GWAS data. All the required scripts are also included. A GWAS analysis can be subdivided into 5 major steps:

1. QC of unimputed data
2. Imputation
3. QC of imputed data
4. Association testing & filtering
5. Regional clustering and plotting

Note: In some cases, scripts, parameters and thresholds need to be adapted to consider certain data proporties.

## Reference files
[GRCh37 reference (fasta.gz)](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz) \
[1000 Genomes allele frequency annotations (vcf.gz)](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.wgs.phase3_shapeit2_mvncall_integrated_v5b.20130502.sites.vcf.gz) \
[1000GP_Phase3_combined.legend.gz](https://www.well.ox.ac.uk/~wrayner/tools/1000GP_Phase3_combined.legend.gz)


## 1. QC of unimputed data
**Script:** qc_unimputed.sh \
**Input data:** Seperate Plink files for cases and controls with sex info and both family id and individual id set \
**Required programs:** plink2.0, plink1.9, bcftools, python3.7, Rscript with libraries qqman and data.table \
**Annotation files:** reference genome (fasta), allele frequency file


## 2. Imputation
For imputation I recommend the Sanger imputation server (free of charge) at https://imputation.sanger.ac.uk/. Either select "pre-phase with EAGLE2 and impute" or "pre-phase with SHAPEIT2 and impute" and upload the final VCF files from step 1. After successfull imputation download the VCF files.


## 3. QC of imputed data
**Script:** qc_imputed.sh \
**Input data:** Input files (*.vcf.gz) from Sanger imputation server. \
**Required programs:** bcftools, vcfparse, IC, Perl module Benchmark \
**Annotation files:** allele frequency file, 1000GP_Phase3_combined.legend


## 4. Association testing & filtering
**Script:** assoc_tests.sh \
**Input data:** Genotypes and sample information in .gen/.sample format (final output of step 3) \
**Required programs:** snptest
