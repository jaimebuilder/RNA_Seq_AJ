#!/bin/bash
#Script name: import samples from NCBI
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 08/05/2025
#Purpose: using sra-toolkit import raw data with accesion number and urls for downloading genome files
#DEPENDENCES: 
#1. sra-tools   GitHub: https://github.com/ncbi/sra-tools
#2. pigz        GitHub: https://github.com/madler/pigz     (Used in alternative code)
readonly VERSION="1.0.1"
#Usage: ./Import_raw_data.sh -f SRR file 
# Possibles flags and arguments:
## -f SRA_file.txt File that contains the SRA accessions of the samples, one per line.
## -h displays help
## -v displays version
## -d genome_fasta url
## -g genome GTF url 
# Usage: $(basename $0) -f SRR_file
readonly help_text="Usage: $(basename $0) -f SRR_file" 

# --------------------------------------------------------------------------------------------

#Parssing arguments
while getopts "hvf:d:g:" opt; do
	case $opt in
    	h) echo ${help_text}
	        exit 0;;
       	v) echo "Version: ${VERSION}"  # Display version info
       		exit 0 ;;
        f) SRR_file="${OPTARG}";;
        d) genome_fasta_url="${OPTARG}";;
        g) genome_GTF_url="${OPTARG}";;
    	?) echo "Invalid option or missing argument: ${help_text}" >&2
       		exit 1 ;;
	esac
done
#Checks if the needed argument is provided
if [[ -z "${SRR_file}" || -z "${genome_fasta_url}" || -z "${genome_GTF_url}" ]]; then 
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

#SRA_file.txt verification
if ! [[ -s "${SRR_file}" ]]; then
        echo "error in SRR file: $SRR_file not found or is empty" >&2
        exit 2
fi

# Logs folder verification or creation
if ! [[ -e "./logs" ]]; then
        echo "./logs directory does not exists, creating..."
        mkdir ./logs
fi

# genome folder verification or creation
if ! [[ -e "./genome_files" ]]; then
        echo "./genome_files directory does not exists, creating..."
        mkdir ./genome_files
fi        

{
#Download genome files
wget -P ./genome_files/ ${genome_fasta_url}
wget -P ./genome_files/ ${genome_GTF_url}

#Download and compress the raw data files (fastq files) by reading every SRR ID (one per line) in SRR file.
while IFS= read -r SRR; do
    prefetch "${SRR}"
    fasterq-dump "${SRR}" --split-files --threads 20 -O ./
    
    # ALTERNATIVE CODE:    
    # An alternative for:  gzip ./*.fastq        is:
    pigz ./*.fastq
    #pigz allows for multiple threads compression, which is faster than normal gzip. By default uses all available threads, however it can be limited using -p N; N is the number of threads.
    #END OF ALTERNATIVE CODE

done < $SRR_file
} 2> >(tee -a ./logs/raw_data_error.log) > >(tee -a ./logs/raw_data_output.log) 
