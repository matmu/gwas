#!/bin/bash


helper_qc_imputed/01_afdist.pl raw/ afdist 20
helper_qc_imputed/01_ic.pl raw/ ic
helper_qc_imputed/02_filter_info.pl raw/ filter 22 0.8 0.01
helper_qc_imputed/03_vcf2gen.pl filter gen 22
