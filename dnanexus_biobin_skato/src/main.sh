#!/bin/bash

set -e -x -o pipefail

main() {
	
	ulimit -c unlimited
	R --quiet -e 'install.packages("SKAT", repos="http://cran.rstudio.com/")'
	
	# switch to a temp directory and download all user input files
	
	NUM_CORES="$(nproc --all)"
	TMPDIR="$(mktemp -d)"
	cd "$TMPDIR"
	mkdir input
	BIOBIN_ROLE_ARG=""
	if [[ -n "$role_file" ]]; then
		dx download "$role_file" -o input/input.role
		BIOBIN_ROLE_ARG="--role-file input/input.role"
	fi
	BIOBIN_PHENO_ARG=""
	BIOBIN_TEST_ARG=""
	if [[ -n "$phenotype_file" ]]; then
		dx download "$phenotype_file" -o input/input.phenotype
		BIOBIN_PHENO_ARG="--phenotype-file input/input.phenotype"
		if [[ ${#regression_type[*]} -gt 0 ]]; then
			BIOBIN_TEST_ARG="--test $(IFS="," ; echo "${regression_type[*]}")"
		fi
	fi
	BIOBIN_COVAR_ARG=""
	if [[ -n "$covariate_file" ]]; then
		dx download "$covariate_file" -o input/input.covariate
		BIOBIN_COVAR_ARG="--covariates input/input.covariate"
	fi
	BIOBIN_WEIGHT_ARG=""
	if [[ -n "$weight_file" ]]; then
		dx download "$weight_file" -o input/input.weight
		BIOBIN_WEIGHT_ARG="--weight-file input/input.weight"
	fi
	BIOBIN_REGION_ARG=""
	if [[ -n "$region_file" ]]; then
		dx download "$region_file" -o input/input.region
		BIOBIN_REGION_ARG="--region-file input/input.region"
	fi
	BIOBIN_INCLUDE_REGION_ARG=""
	if [[ -n "$include_region_file" ]]; then
		dx download "$include_region_file" -o input/input.gene
		BIOBIN_INCLUDE_REGION_ARG="--include-region-file input/input.gene"
	fi
	if [[ "$biobin_args" = *"weight-loci"* ]]; then
		echo "Please dont add weight-loci in biobin Arguments option instead use the drop down selection and rerun the program. Exiting!"
		exit -1
	fi
	BIOBIN_WEIGHING_ARG=""
	if [[ $(IFS="," ; echo "${weight_loci[*]}") = "madsen-browning" ]]; 
	then
		BIOBIN_WEIGHING_ARG="--weight-loci Y"
	else
		BIOBIN_WEIGHING_ARG="--weight-loci N"
	fi

	VCF_FILE="input/input.vcf.gz"
	TBI_FILE="$VCF_FILE.tbi"
	dx download "$vcf_file" -o "$VCF_FILE"
	if [[ -n "$vcf_tbi_file" ]]; then
		dx download "$vcf_tbi_file" -o "$TBI_FILE"
	else
		tabix -p vcf "$VCF_FILE" 2>&1 | tee -a output.log
	fi
	
	
	# fetch the executable(s) and shared resource file(s)
	
	mkdir bin
	mkdir shared
#	DX_RESOURCES_ID="$(dx find projects --name "App Resources" --brief)"
#	DX_RESOURCES_ID="project-BYpFk1Q0pB0xzQY8ZxgJFv1V"	
	
	# if [[ -z "$biobin_binary_exec" ]]; then
	# 	dx_pathname="Ritchie Lab Software:/BioBin/versions/biobin"
	# 	dx_filename="$(dx ls "$dx_pathname" | sort -r | head -n 1)"
	# 	biobin_binary_exec="$(dx find data \
	# 		--path "$dx_pathname" \
	# 		--name "$dx_filename" \
	# 		--brief \
	# 	)"
	# 	echo "Latest binary: $dx_pathname/$dx_filename"
	# fi
	# dx download "$biobin_binary_exec" -o bin/biobin
	# chmod +x bin/biobin
	
	if [[ -z "$biobin_summary_script" ]]; then
		dx_pathname="Ritchie Lab Software:/BioBin/versions/biobin-summary.py"
		dx_filename="$(dx ls "$dx_pathname" | sort -r | head -n 1)"
		biobin_summary_script="$(dx find data \
			--path "$dx_pathname" \
			--name "$dx_filename" \
			--brief \
		)"
		echo "Latest summary script: $dx_pathname/$dx_filename"
	fi
	dx download "$biobin_summary_script" -o bin/biobin-summary.py
	chmod +x bin/biobin-summary.py
	
	if [[ -z "$loki_db" ]]; then
		dx_pathname="Ritchie Lab Software:/LOKI"
		dx_filename="$(dx ls "$dx_pathname" | sort -r | head -n 1)"
		loki_db="$(dx find data \
			--path "$dx_pathname" \
			--name "$dx_filename" \
			--brief \
		)"
		echo "Latest LOKI: $dx_pathname/$dx_filename"
	fi
	dx download "$loki_db" -o shared/loki.db
	
	
	BIOBIN_TEST_ARG1="$BIOBIN_TEST_ARG"
	if [[ "$BIOBIN_TEST_ARG" = *"SKATO-logistic"* ]]; then
		BIOBIN_TEST_ARG1="--test SKAT-logistic"
	elif [[ "$BIOBIN_TEST_ARG" = *"SKATO-linear"* ]]; then
		BIOBIN_TEST_ARG1="--test SKAT-linear"
	fi
	# run biobin

	mkdir biobin
	biobin_intermediate \
		--threads "$NUM_CORES" \
		--settings-db shared/loki.db \
		--vcf-file "$VCF_FILE" \
		$BIOBIN_ROLE_ARG \
		$BIOBIN_PHENO_ARG \
		$BIOBIN_COVAR_ARG \
		$BIOBIN_TEST_ARG1 \
		$BIOBIN_WEIGHT_ARG \
		$BIOBIN_REGION_ARG \
		$BIOBIN_INCLUDE_REGION_ARG \
		$BIOBIN_WEIGHING_ARG \
		--report-prefix "biobin/$output_prefix" \
		$biobin_args \
	2>&1 | tee -a output.log
	ls -laR biobin
	
	RGX="--force-all-control[[:space:]]+(y|Y)"
	ALL_CONTROL=""
	if [[ $biobin_args =~ $RGX ]]; then
		ALL_CONTROL="--all-control"
	fi
	
	# run summary script
	
	python bin/biobin-summary.py \
		--prefix="biobin/$output_prefix" \
		$ALL_CONTROL \
		> "biobin/summary.tsv"
	
	
	if [[ $(IFS="," ; echo "${regression_type[*]}") = "SKAT"* ]]; then
		echo "Running SKAT/SKATO using R package"
		Rscript /usr/bin/SKAT_run.R $(IFS="," ; echo "${regression_type[*]}") $(IFS="," ; echo "${weight_loci[*]}") "$NUM_CORES"
		Rscript /usr/bin/merge_summary_skato.R
		summary_file=$(dx upload results_summary.csv --brief)
		dx-jobutil-add-output summary_file --class="file" "$summary_file"
		mv outfile_parallel_log "${output_prefix}.log"
	else
		mv output.log "${output_prefix}.log"
		summary_file=$(dx upload biobin/summary.tsv --brief)
		dx-jobutil-add-output summary_file --class="file" "$summary_file"
	fi
	
	# upload output files
	
	for f in biobin/*-bins.csv ; do
		bin_file=$(dx upload "$f" --brief)
		dx-jobutil-add-output bins_files --class="array:file" "$bin_file"
	done
	
	locus_file=$(dx upload biobin/*-locus.csv --brief)
	dx-jobutil-add-output locus_file --class="file" "$locus_file"
	
	log_file=$(dx upload "${output_prefix}.log" --brief)
	dx-jobutil-add-output log_file --class="file" "$log_file"
	
	for f in biobin/*-unlifted.csv ; do
		if [[ -f "$f" ]]; then
			unlifted_file=$(dx upload "$f" --brief)
			dx-jobutil-add-output unlifted_files --class="array:file" "$unlifted_file"
		fi
	done
	
}
