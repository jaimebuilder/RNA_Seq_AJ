#!/bin/bash
#Script name: post_fastqc
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: using fastqc and multiqc for checking quality AFTER trimming and filtering
#DEPENDENCES:
#1. fastqc		GitHub: https://github.com/s-andrews/FastQC
#2. multiqc		GitHub: https://github.com/MultiQC/MultiQC
readonly VERSION="1.0.0"
#Possible flags and arguments:
## -i input directory
## -o output directory
## -h displays help
## -v displays version
#Usage: $(basename $0) -i input_dir -o out_dir
readonly help_text="Usage: $(basename $0) -i input_dir -o out_dir "

#------------------------------------------------------------------------------------------

#Parssing arguments
while getopts "hvi:o:" opt; do
	case $opt in
    	h) echo $help_text #Displays help
			exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
    	i) inputDir="$OPTARG" ;;
		o) outputDir="$OPTARG" ;;
    	*) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

#Checking if both arguments are provided. The assigned variables are not empty.
if [[ -z "$inputDir" || -z $outputDir ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

#Creating logs folder inside the output directory if it does not exit previously.
if ! [[ -e $outputDir/logs ]]; then
                echo "$outputDir/logs directory does not exists, creating..."
                mkdir $outputDir/logs
				echo "$outputDir/logs created"
fi

#Creating fastqc folder inside the output directory if it does not exit previously.
if ! [[ -e $outputDir/fastqc ]]; then
                echo "$outputDir/fastqc directory does not exists, creating..."
                mkdir $outputDir/fastqc
				echo "$outputDir/fastqc created"
fi

#Running fasqc and multiqc and saving the standar outputs and the standar errors in the logs folder. 
{

fastqc ${inputDir}/*_1_cleaned.fastq.gz ${inputDir}/*_2_cleaned.fastq.gz -o ${outputDir}/fastqc -t 20   #Call fastqc with both forward and reverse samples, -o for output directory and -t for the threads fastqc could use.
multiqc ${outputDir}/fastqc -o ${outputDir}/multiqc     # Call multiqc with the output of fastqc, -o is for output directory.

} 2> >(tee -a $outputDir/logs/post_fastqc_error.log) > >(tee -a $outputDir/logs/post_fastqc.log) #tee comand allows us to redirect stdout/stderr to the terminal and to a file at the same time.