#!/bin/bash
#Script name: counts_alignment
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: Obtaining the file with the number of counts correponding to each gene using the Bam file obtained after the alingment.
#DEPENDENCES: 
#1. featureCounts		GitHub: https://github.com/gih0004/RNA_Seq_featurecounts
readonly VERSION="1.0.0"
#Possible flags and arguments:
## -d input_directory. Directory that contains the results of the alignment. It is the same than the Output directory specified during the alingment.
## -g GTF file
## -h displays help
## -v displays version
#Usage: ./Import_raw_data.sh -i input_directory
readonly help_text="Usage: $(basename $0) -i input_dir -g GTF_file"

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

#Checking if both arguments are provided. The assigned variables are not empty.
if [[ -z "${input_dir}" || -z "{$GTF}" ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

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
    $input_dir/SRR*/results/STAR/*sortedByCoord.out.bam # Take all the bam files corresponding to each sample as an input for featureCounts tool. The input folder is the same as the output folder of the alignment.
    #Explanation fo featureCounts options:
    ## -a Annotation file (GTF)
    ## -o Output folder where you want to store the counts file
    ## -T Number of threads used
    ## -p Activate pair-end mode 
    ## -s Strandedness (2, for reverse-stranded)
    ## -t Feature type to count (exon)
    ## -g GTF attribute used to group exons into genes (gene_id)

echo "Counts completed."

} 2> >(tee -a ./logs/counts_error.log) > >(tee -a ./logs/counts_output.log) 


#Now a little text processing on the output for making it fully compatible with the next R script for differential analysis
{
echo "Starting text processing of the output"

sed -i "2 s;${input_dir}/\(SRR[0-9]*\)/results/STAR/[a-zA-Z0-9.]*;\1;g" ./counts.txt
#This sed command does:
#-i flag for in-place modification (modifies directly the provided file, similar to redirect stdout to the file >./counts.txt)
#Searchs in the line 2 (second line) the regular expresion "${input_dir}/\(SRR[0-9]*\)/results/STAR/[a-zA-Z0-9.]*" which is the path and name of the corresponding BAM file features counts uses for each column of the output.
#The pattern is then changed to captured pattern
#g is for global (changes all matches)
#The part in the regex between \(   \) is captured and used for substitution as "\1"
#The delimiter used in this case is ";" rather than typical "/". This allows the character "/" to be part of the regex
#Example of how this command works: 
#Before: "../04-reads_alignment//SRR12506729/results/STAR/Aligned.sortedByCoord.out.bam	../04-reads_alignment//SRR12506733/results/STAR/Aligned.sortedByCoord.out.bam"   (sed command)--> AFTER:  "SRR12506729 SRR12506733"

echo "Finished text processing, output ready for next step"

} 2> >(tee -a ./logs/text_processing_error.log) > >(tee -a ./logs/text_processing_output.log) 



