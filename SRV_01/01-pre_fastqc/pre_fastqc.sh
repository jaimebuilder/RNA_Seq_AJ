#!/bin/bash
#Script name: pre_fastqc
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: using fastqc and multiqc for checking quality BEFORE trimming and filtering
#DEPENDENCES: fastqc and multiqc
readonly VERSION="1.0.0"
#-i input directory
#-o output directory
#-h displays help
#-v displays version
readonly help_text="Usage: $(basename $0) -i input_dir -o out_dir "

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

if [[ -z "$inputDir" || -z $outputDir ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

if ! [[ -e $outputDir/logs ]]; then
                echo "$outputDir/logs directory does not exists, creating..."
                mkdir $outputDir/logs
				echo "$outputDir/logs created"
fi

if ! [[ -e $outputDir/fastqc ]]; then
                echo "$outputDir/fastqc directory does not exists, creating..."
                mkdir $outputDir/fastqc
				echo "$outputDir/fastqc created"
fi

{

fastqc ${inputDir}/*_1.fastq.gz ${inputDir}/*_2.fastq.gz -o ${outputDir}/fastqc -t 20   #Call fastqc with both forward and reverse samples, -o for output directory and -t for the threads fastqc could use.
multiqc ${outputDir}/fastqc -o ${outputDir}/multiqc     # Call multiqc with the output of fastqc, -o is for output directory.

} 2> >(tee -a $outputDir/logs/pre_fastqc_error.log) > >(tee -a $outputDir/logs/pre_fastqc.log) 