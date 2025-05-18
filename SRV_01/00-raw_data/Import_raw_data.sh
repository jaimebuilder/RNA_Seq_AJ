#!/bin/bash
#Script name: import samples from NCBI
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: using sra-toolkit import raw data with accesion number
#DEPENDENCES: sra-tools
readonly VERSION="1.0.0"
#Usage: ./Import_raw_data.sh -f SRR file 
# El script requiere estos argumentos, con las siguientes flags:
#1. -f SRA_file.txt File that contains the SRA accessions of the samples, one per line.
#-h displays help
#v displays version
help_text="Usage: $(basename $0) -f SRR_file"

#Parssing arguments
while getopts "hvf:" opt; do
	case $opt in
    	h) echo $help_text
	        exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
        f) SRR_file="$OPTARG";;
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

if [[ -z "$SRR_file" ]]; then #Checks if the needed argument is provided
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

#SRA_file.txt verification
if ! [[ -s $SRR_file ]]; then
        echo "error in SRR file: $SRR_file not found or is empty" >&2
        exit 2
fi

# Logs folder verification or creation
if ! [[ -e ./logs ]]; then
                echo "./logs directory does not exists, creating..."
                mkdir ./logs
        fi

{
while IFS= read -r SRR; do
    prefetch $SRR
    fasterq-dump $SRR --split-files --threads 20 -O ./
    gzip ./*.fastq
done < $SRR_file
} 2> >(tee -a ./logs/raw_data_error.log) > >(tee -a ./logs/raw_data_output.log) 