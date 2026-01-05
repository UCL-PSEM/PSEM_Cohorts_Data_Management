#################################################################################################
###########Pipeline for Extracting SNPs for Genetic Analyses from QCed ALSPAC Data###############
#######Adapted from UKB code originally available at https://github.com/asalzy/MRPipeline########
#################################################################################################

#!/bin/bash

##Default values for arguments
#By default the output produced is a bgen/gen file called "extracted_snps"
#These can be overwritten by params file or argument flags in the command line

output_name=extracted_snps
out_dir=.

#Get location of QCed Data, snp_list and out_directory from params file

dir_path="$(dirname $(realpath $0))/params"          
echo "Looking for params file in $dir_path..."
if [ -f $dir_path ]; then
	echo "Found params file"
	source $dir_path
else
	echo "Could not find params file - please double-check installation instructions at https://github.com/scottchiesa/ALSPAC_SNP_Extraction"
	exit 1 
fi

function Help () {
        # Display Help
        echo "The ALSPAC_SNP_Extraction program simplifies the extraction of SNPs from QCed ALSPAC data. SNPs can be extracted as .gen or .bgen files."
        echo
        echo "Syntax: ALSPAC_SNP_Extraction <options>"
        echo
        echo "options:"
        echo
        echo "-s <a>:     (Optional) Path of SNP list to operate on. The SNP list needs to be a text file with one SNP chrpos per line. Including this argument will override any default SNP list defined in the params file."
        echo 
	echo "-h:         Print this Help."
        echo 
	echo "-b:         Specify that pipeline should output extracted SNPs in a .bgen format. The user must select either the -b flag or the -g flag (or both)."
        echo 
	echo "-g:         Specify that pipeline should output extracted SNPs in a .gen format. The user must select either the -b flag or the -g flag (or both)."
        echo 
	echo "-o <a>:     (Optional) Path to output directory. Including this argument will override any default defined in the params file."
        echo
	echo "-n <a>:     (Optional) name for output file. Including this argument will override any default defined in the params file."
        echo
}


## Get arguments for function
# Arguments include -s for location of snplist file, b for bgen output, g for gen output, -o for output directory, -n for name of output

bgen=0
gen=0

while getopts "s:bgho:n:" flag
do

        case "${flag}" in
		h) #Display help 
			Help
			exit;; 
                s) snp_list=${OPTARG} #enter snplist location
                        ;;
                b) bgen=1 #output bgen file
                        ;;
                g) gen=1 #output gen file
                        ;;
                o) out_dir=${OPTARG} #set output directory
                        ;;
                n) output_name=${OPTARG} #set file name
                        ;;
                \?) echo "ERROR: Invalid option: -$OPTARG"
                        echo "use the -h flag to see the help page"
			exit 1
                        ;;
                :) echo "ERROR: Option -$OPTARG requires an argument."
                        echo "use the -h flag to see the help page"
			exit 1
                        ;;

                esac

done

#Check that either -g or -b flag is present 

if [ $gen = 0 ] && [ $bgen = 0 ]; then
echo "You need to include either the -b (bgen) or -g (gen) flag (or both)"
fi

#Make output directory if required (doesnt throw error if not present)

mkdir -p $out_dir

#If asking for genotype output

if [ $gen = 1 ]; then
        echo "Outputting as gen file..."
        #Loop through chomosomes in QCed data
        for i in {01..22}; do
                /shared/ucl/apps/bgen/1.1.4/bin/bgenix \
                -g ${ALSPAC_QC}/filtered_${i}.bgen \
                -incl-range $snp_list | \

                #pipe to qctool to convert to gen
                /shared/ucl/apps/qctool/ba5eaa44a62f/bin/qctool_v2.0.1 -g - -filetype bgen \
                -og ${out_dir}/Chr${i}_extracted_snps.gen

                #concatenate gen files into merged file
                if [ -f ${out_dir}/Chr${i}_extracted_snps.gen ] ; then
                        cat ${out_dir}/Chr${i}_extracted_snps.gen >> ${out_dir}/extracted_SNPs_plus_col.gen
                        awk '{$2=""; print $0}' ${out_dir}/extracted_SNPs_plus_col.gen >> ${out_dir}/${output_name}.gen

                #Remove irrelevant files
                rm ${out_dir}/extracted_SNPs_plus_col.gen
                rm ${out_dir}/Chr${i}_extracted_snps.gen

                fi
        done
fi

if [ $bgen = 1 ]; then 
        echo "Outputting as bgen file..."
        #Loop extracting SNPs from SNP list as bgen 
        for i in {01..22}; do 
                echo "Extracting SNPs from chromosome ${i}..."
                #Extract the SNPs as bgen 
                /shared/ucl/apps/bgen/1.1.4/bin/bgenix \
                -g ${ALSPAC_QC}/filtered_${i}.bgen \
                -incl-range $snp_list > ${out_dir}/Chr${i}_extracted_snps.bgen
                
                
        done
        
        #Concatenate Bgen files 

        echo "Concatenating bgen files into single output..."
        /shared/ucl/apps/bgen/1.1.4/bin/cat-bgen \
        -clobber -g ${out_dir}/Chr{01..22}_extracted_snps.bgen \
        -og ${out_dir}/${output_name}.bgen
        
        #Remove intermediate files 

        echo "Removing intermediate files..."
        rm ${out_dir}/Chr{01..22}_extracted_snps.bgen
        
fi 