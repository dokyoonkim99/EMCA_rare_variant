# EMCA Rare variant analysis

The rare variant binning and association testing was performed on DNAnexus (https://www.dnanexus.com/) cloud computing platform. Though we used DNAnexus, biobin can be run as stand alone executable.

## Biobin
This app runs the BioBin software, which is a comprehensive bioinformatics tool for biologically-driven binning and association analysis of rare variants (RVs) in sequence data. It automates multi-level binning or collapsing of RVs into biological features such as genes, pathways, regulatory regions, evolutionary conserved regions (ECRs), and many others. BioBin improves on other variant binning algorithms through the use of prior biological information, which can highlight the potential cumulative effects of biologically aggregated RVs. BioBin requires the Library of Knowledge Integration (LOKI), which contains diverse biological knowledge from multiple collections of publically available databases. 

## dnanexus_biobin_skato
This app runs the BioBin software on DNAnexus. To build this app on DNAnexus refer to instructions at https://wiki.dnanexus.com/Developer-Tutorials/Intro-to-Building-Apps

## BioBin standalone
You can download the latest source code from: https://ritchielab.org/software/biobin-download
For this analysis we used BioBin version - 2.3.0 Released April 17, 2017
The source code can also be found on Github - https://github.com/RitchieLab/biobin

## What data was used to run BioBin?

This app requires a VCF file to run. For more information on which input files to use and on the format of input files, please refer to the software manual http://www.ritchielab.com/software/biobin-download.
input files that need to be included:
  - Phenotype file (`*.phe`)
  - Covariate file (`*.cov`)
  - BioBin Summary Script (python script to summarize results, provided with software download)
  - LOKI database

## How to build LOKI?
LOKI is integrated database of biological knowledge from various sources including Entrez and KEGG which are used in this analysis to define gene/pathway boundaries. The scripts to build loki (loki-build.py) are provided with the copy of biobin download.

loki-build.py --verbose --knowledge loki_04152019.db --update

## Biobin command used in this analysis
### Gene based binning
biobin --settings-db LOKI.db --vcf-file vcf_file --phenotype-file phe_file --covariates cov_file --test test_type --weight-loci Y --bin-pathways N --bin-regions Y --genomic-build 38 --bin-interregion N -m 20 --maf-cutoff 0.05"

### Pathway based binnning
biobin --settings-db LOKI.db --vcf-file vcf_file --phenotype-file phe_file --covariates cov_file --test test_type --weight-loci N --bin-pathways Y --bin-regions N --genomic-build 38 --bin-interregion N -m 20 --maf-cutoff 0.05 --include-sources kegg,entrez"

NOTE: If you build the dnanexus app, then similar options can be selected in the UI. Also other softwares like rvtests (https://github.com/zhanxw/rvtests) and EPACTS (https://genome.sph.umich.edu/wiki/EPACTS) can also be used. The results would be similar - slight variation might be seen depending upon how multiallelic sites and star alleles (https://software.broadinstitute.org/gatk/documentation/article.php?id=6926) are handled.
