#!/bin/bash
#Script name: counts_alignment
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: Realizar las cuentas del alinemiento
#DEPENDENCES: featureCounts
readonly VERSION="1.0.0"
#Usage: ./Import_raw_data.sh -i input_directory
# El script requiere estos argumentos, con las siguientes flags:
#1. -d input_directory. Directory that contains the results of the alignment. It is the same than the Output directory specified during the alingment.
#2. -g GTF file
#-h displays help
#v displays version
readonly help_text="Usage: $(basename $0) -i input_dir"

#Parssing arguments
while getopts "hvi:g:" opt; do
	case $opt in
    	h) echo $help_text
			exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
        i) input_dir="$OPTARG"
        g) GTF="$OPTARG"
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

#Input directory verification
if ! [[ -s $input_dir ]]; then
        echo "error in input directory: $inut_dir not found or is empty" >&2
        exit 2
fi

# Logs folder verification or creation
if ! [[ -e ./logs ]]; then
                echo "./logs directory does not exists, creating..."
                mkdir ./logs
fi


#Obtainig counts files using featuresCounts
{
featureCounts \
-a $GTF \
-o ./$sample/counts.txt \
-T 20 \
-p \
-s 2 \
-t exon \
-g gene_id \
$input_dir/SRR*/results/STAR/*sortedByCoord.out.bam
} >> ./logs/counts_output.log 2>> ./logs/counts_error.log

