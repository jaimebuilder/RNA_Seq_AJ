#!/bin/bash
#Script name: import samples from NCBI
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: using sra-toolkit import raw data with accesion number and import GTF_file
#DEPENDENCES: sra-tools
#Usage: ./Import_raw_data.sh -f SRA file 
# El script requiere estos argumentos, con las siguientes flags:
#1. -f SRA_file.txt File that contains the SRA accessions of the samples, one per line.
#2. -g URL from the GTF file that we will use
#-h displays help
#v displays version


#Parssing arguments
while getopts "hvf:" opt; do
	case $opt in
    	h) echo $help_text
		exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
        f) SRA_file="$OPTARG" ;;
        g) GTF_URL="$OPTARG" ;;
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

#SRA_file.txt verification
if ! [[ -s $SRA_file ]]; then
        echo "error in Genome Annotation file: $SRA_file not found or is empty" >&2
        exit 2
fi

# Logs folder verification or creation
if ! [[ -e ./logs ]]; then
                echo "./logs directory does not exists, creating..."
                mkdir ./logs
fi
#Obtaining GTF_file
if ! [[ -e ../genome_files/*.gtf ]]; then
                echo "GTF_file does not exit. Downloading..."
                wget -P ../genome_files/ $GTF_URL 
fi


#Obtaining fastq.gz files from NCBI using sra-tools
{
while IFS= read -r SRA; do
    prefetch $SRA
    fasterq-dump $SRA --split-files --threads 20 -O ./
    gzip ./*.fastq
done < $SRA_file
} >> ./logs/raw_data_output.log 2>> ./logs/raw_data_alignment_error.log