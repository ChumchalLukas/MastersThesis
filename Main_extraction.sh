#!/bin/bash


# Data extraction: script for extracting main data

# Sorting files by sample
sorting_files(){
    for VAR in "${UsedFiles[@]}"; do
        bcftools query -l "${VAR}.vcf" | sort -V > "samples_${VAR}.txt"
        bcftools view -S "samples_${VAR}.txt" "${VAR}.vcf" > "${VAR}_columns.vcf"
    done

    if [[ "$?" -eq 0 ]]; then
        echo "Column sorting ended."
    else
        echo "Sorting bug!"
        exit 1
    fi
    return
}

# Genotypes Files


making_genotypes_files(){
	for VAR in "${UsedFiles[@]}";do
		bcftools view "${VAR}_columns.vcf" | bcftools query -f "%CHROM\t%POS\t%REF\t%ALT\t%ID\t%G5\t%COMMON\t%dbNSFP_PHRED\t%QUAL\t%FORMAT\n" > "${VAR}_format.txt"
		java -jar /home/sachal/snpEff/SnpSift.jar extractFields -s "," -e "." ${VAR}_columns.vcf POS "ANN[*].GENE" "ANN[*].FEATUREID" "ANN[*].HGVS_C" "ANN[*].HGVS_P" "ANN[*].RANK" "ANN[*].EFFECT" "ANN[*].IMPACT" > "${VAR}_Eff.txt"
		awk 'NR!=1' "${VAR}_Eff.txt" > "${VAR}_Eff_awk.txt"
		paste -d "\t" "${VAR}_format.txt" "${VAR}_Eff_awk.txt" > "${VAR}_variace_GT.txt"
	done

	if [[ "$?" -eq "0" ]];then
		echo "Variance file done successfully."
	else
		echo "Bug in process of creating variance files!"
	fi
	return
}

# Filtering propably pathogenic variance

filtering_files(){
	for VAR in "${UsedFiles[@]}";do
		java -jar /home/sachal/snpEff/SnpSift.jar filter "((ANN[*].IMPACT has 'HIGH') | (ANN[*].IMPACT has 'MODERATE')) & ((CLNSIG !~ 'Benign') | (na CLNSIG)) & ((na AF_nfe) | (AF_nfe < 0.01)) & ((na dbNSFP_1000Gp3_EUR_AF) | (dbNSFP_1000Gp3_EUR_AF < 0.01)) & !(exists G5) & ((na dbNSFP_PHRED) | (dbNSFP_PHRED > 15))" -f "${VAR}_columns.vcf" > "${VAR}_filtered.vcf"
	done

	if [[ "$?" -eq "0" ]];then
		echo "Filetering successfull."
		echo "Ready to use."
	else
		echo "Filtering bug!"
		exit 1
	fi
	return
}

making_suspected_files(){
	for VAR in "${UsedFiles[@]}";do
		bcftools view "${VAR}_filtered.vcf" | bcftools query -f "%CHROM\t%POS\t%REF\t%ALT\t%ID\t%AF\t%AB\t%DP\t%RO\t%AO\t%TYPE\t%dbNSFP_Interpro_domain\t%CLNSIG\t%CLNDN\t%CLNSIGINCL\t%CLNREVSTAT\t%MUT\t%G5\t%G5A\t%COMMON\t%dbNSFP_PHRED\t%dbNSFP_REVEL_score\t%dbNSFP_VEST4_score\t%dbNSFP_DANN_score\t%dbNSFP_LINSIGHT\t%dbNSFP_Eigen_phred_coding\t%dbNSFP_Eigen_PC_phred_coding\t%dbNSFP_MetaSVM_pred\t%dbNSFP_MetaLR_pred\t%dbNSFP_M_CAP_pred\t%dbNSFP_Polyphen2_HDIV_pred\t%dbNSFP_Polyphen2_HVAR_pred\t%dbNSFP_SIFT_pred\t%dbNSFP_LRT_pred\t%dbNSFP_MutationAssessor_pred\t%dbNSFP_MutationTaster_pred\t%dbNSFP_PROVEAN_pred\t%dbNSFP_FATHMM_pred\t%dbNSFP_BayesDel_addAF_pred\t%dbNSFP_BayesDel_noAF_pred\t%dbNSFP_ClinPred_pred\t%dbNSFP_LIST_S2_pred\t%dbNSFP_Aloft_pred\t%dbNSFP_rf_score\t%dbNSFP_ada_score\t%dbNSFP_phastCons100way_vertebrate\t%AF_popmax\t%AF_nfe\t%nhomalt_nfe\t%AN_nfe\t%controls_AF\t%controls_nhomalt\t%controls_AN\t%controls_AF_nfe\t%controls_AN_nfe\t%dbNSFP_1000Gp3_AF\t%dbNSFP_1000Gp3_EUR_AF\t%dbNSFP_ExAC_NFE_AF\n" > "${VAR}_query.txt"
		java -jar /home/sachal/snpEff/SnpSift.jar extractFields -s "," -e "." ${VAR}_filtered.vcf POS "ANN[*].GENE" "ANN[*].FEATUREID" "ANN[*].HGVS_C" "ANN[*].HGVS_P" "ANN[*].RANK" "ANN[*].EFFECT" "ANN[*].IMPACT" "ANN[*].ERRORS" > ${VAR}_SnpEff.txt
		awk 'NR!=1' "${VAR}_SnpEff.txt" > "${VAR}_SnpEff_awk.txt"
		paste -d "\t" "${VAR}_query.txt" "${VAR}_SnpEff_awk.txt" > "${VAR}_SUSPECTED.txt"
	done

	if [[ "$?" -eq "0" ]];then
		echo "Extraction completed."
	else
		echo "Extraction pathogenic variations bug!"
	fi
	return
}

# Functions execution

main(){
	# Names used files
	declare -a UsedFiles=("Exones" "Genes")

	echo "Running script..."
	echo "Date: $(date)"

	echo "Sorting files..."
	sorting_files

	echo "Creating files for analysis according genotypes..."
	making_genotypes_files

	echo "Applying specific filter..."
	filtering_files

	echo "Creating files for analysis accroding bioinformatics tools scores..."
	making_suspected_files

	return
}



# File execution

main