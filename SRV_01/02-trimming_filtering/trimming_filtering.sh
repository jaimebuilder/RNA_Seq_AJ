#!/bin/bash
#Script name: trimming_filtering
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: trimming and filtering raw data
#DEPENDENCES: fastp
readonly VERSION="1.0.0"
#-i input directory
#-o output directory
#-h displays help
#-v displays version
readonly help_text="Usage: $(basename $0) -i input_dir -o out_dir -f SRR_file"

#Parssing arguments
while getopts "hvi:o:f:" opt; do
	case $opt in
    	h) echo $help_text #Displays help
			exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
    	i) inputDir="$OPTARG" ;;
		o) outputDir="$OPTARG" ;;
        f) SRR_file="$OPTARG";;
    	*) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

if [[ -z "$inputDir" || -z $outputDir || -z $SRR_file ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

if ! [[ -e $outputDir/logs ]]; then
                echo "$outputDir/logs directory does not exists, creating..."
                mkdir $outputDir/logs
                echo "$outputDir/logs created"
fi

{
while IFS= read -r SRR; do
   fastp \
  -i ${inputDir}/${SRR}_1.fastq.gz \ 
  -I ${inputDir}/${SRR}_2.fastq.gz \ 
  -o ${outputDir}/${SRR}_1.cleaned.fastq.gz \ 
  -O ${outputDir}/${SRR}_2.cleaned.fastq.gz \ 
  -h ${outputDir}/${SRR}_report.html \ 
  -j ${outputDir}/${SRR}_report.json \
  -w 16 \
  --detect_adapter_for_pe \
  -q 20 \
  --length_required 30 \
  #fastp opts: fwd and revers inputs and outputs,  Crea reports html y json (opcionales, pues luego se realizara con fastqc) Autodetects adapter in Pair Ends, samples Filters any read below 20 phred score. reads shorter than 30 will be discarded

done < $SRR_file

} 2> >(tee -a $outputDir/logs/trimming_error.log) > >(tee -a $outputDir/logs/trimming.log)
