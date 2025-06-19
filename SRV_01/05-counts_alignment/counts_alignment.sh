#!/bin/bash
#Script name: counts_alignment
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: Obtaining the file with number of counts correponding to each gene using the Bam file obtained after the alingment.
#DEPENDENCES: 
#1. featureCounts		GitHub: https://github.com/gih0004/RNA_Seq_featurecounts
readonly VERSION="1.0.0"
#Possible flags and arguments:
## -d input_directory. Directory that contains the results of the alignment. It is the same than the Output directory specified during the alingment.
## -g GTF file
## -h displays help
## -v displays version
#Usage: ./Import_raw_data.sh -i input_directory
readonly help_text="Usage: $(basename $0) -i input_dir"

#-------------------------------------------------------------------------------------------

#Parssing arguments
while getopts "hvi:g:" opt; do
	case $opt in
    	h) echo $help_text
			exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
        i) input_dir="$OPTARG" ;;
        g) GTF="$OPTARG" ;;
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

#Input directory verification
if ! [[ -s "${input_dir}" ]]; then
        echo "error in input directory: ${input_dir} not found or is empty" >&2
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
    -o ./counts.txt \
    -T 20 \
    -p \
    -s 2 \
    -t exon \
    -g gene_id \
    $input_dir/SRR*/results/STAR/*sortedByCoord.out.bam
} 2> >(tee -a ./logs/counts_error.log) > >(tee -a ./logs/counts_output.log) 
echo "Counts completed."

#Explanation fo featureCounts options:
## -a Annotation file (GTF)
## -o Output folder where you want to store the counts file
## -T Number of threads used
## -p Activate pair-end mode 
## -s Strandedness (2, for reverse-stranded)
## -t Feature type to count (exon)
## -g GTF attribute used to group exons into genes (gene_id)