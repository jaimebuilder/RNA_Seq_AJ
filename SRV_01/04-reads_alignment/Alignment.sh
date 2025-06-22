#!/bin/bash
#Script name: RNA-Seq Alignment with Multiple Aligners and Output Management
#Author: Jaime Salama García & Alberto Romero Lucas
#Date: 23/04/2025
#Purpose: A Bash script that automates RNA-Seq alignment for multiple samples.
#Usage: $(basename $0) -i input_reads_dir -F _R1.fastq -R _R2.fastq -f genome/genome.fa -g genome/annotation.gtf -o out_dir -s sample_list.txt
readonly VERSION="1.0.4"
# Possibles flags and arguments:
## -i Input Directory containing the FASTQ files
## -F Forward Read Suffix/Pattern (e.g., _R1.fastq or _1.fastq.gz)
## -R Reverse Read Suffix/Pattern (e.g., _R2.fastq or _2.fastq.gz)
## -f Genome Reference file (FASTA format)
## -g Genome Annotation file (GTF format)
## -o Output Folder where results will be saved
## -s Sample List: A file containing the base names of each sample (without the _R1 or _R2 part)
## -h displays help
## -v displays version
readonly help_text="Usage: $(basename $0) -i input_reads_dir -F _R1.fastq -R _R2.fastq -f genome/genome.fa -g genome/annotation.gtf -o out_dir -s sample_list.txt"

# --------------------------------------------------------------------------------------------

#Parssing arguments
while getopts "hvi:F:R:f:g:o:s:" opt; do
	case $opt in
    	h) echo $help_text
			exit 0;;
       	v) echo "Version: $VERSION"  # Display version info
       		exit 0 ;;
    	i) inputDir="$OPTARG" ;;
		F) FRPattern="$OPTARG" ;;
		R) RRPattern="$OPTARG" ;;
		f) genome_fasta="$OPTARG" ;;
		g) genome_GTF="$OPTARG" ;;
		o) outputDir="$OPTARG" ;;
		s) sample_list="$OPTARG" ;;
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

if [[ -z "$inputDir" || -z "$outputDir" || -z "$FRPattern" || -z "$RRPattern" || -z "$genome_fasta" || -z "$genome_GTF" || -z "$sample_list" ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

#File validation:
#Genome fasta file
if ! [[ -s $genome_fasta ]]; then
	echo "error in Genome Reference file: $genome_fasta not found or is empty" >&2
	exit 2
fi
#genome GTF file
if ! [[ -s $genome_GTF ]]; then
        echo "error in Genome Annotation file: $genome_GTF not found or is empty" >&2
        exit 2
fi
#Input Directory
if ! [[ -s $inputDir && -d $inputDir ]]; then
        echo "error in input directory: $inputDir not found, is empty or is not a directory" >&2
        exit 2
fi
#sample list file
if ! [[ -s $sample_list ]]; then
        echo "error in sample list file: $sample_list not found or is empty" >&2
        exit 2
fi


#Create output directory and subdirectories:
echo "Creating output directory..."

if ! [[ -e $outputDir ]]; then
	echo "Output directory does not exists, creating..."
	mkdir $outputDir
fi

if ! [[ -e $outputDir/indices ]]; then
	echo "Creating $outputDir/indices directory"
	mkdir $outputDir/indices
fi
#Creating log directory
if ! [[ -e $outputDir/indices/logs ]]; then
	echo "Creating $outputDir/indices/logs directory"
	mkdir $outputDir/indices/logs
fi

#Creating index of the selected aligner
{
#Alignment will be carried out by STAR.
#First, STAR need genome indices.
#Checks if indices are already created
if [ -d "${outputDir}/indices/STAR_genome_indices" ] && [ "$(ls  ${outputDir}/indices/STAR_genome_indices)" ]; then
    echo "STAR indices already created, skipping indices generation..."
else
	echo "STAR selected, creating indices..."
	STAR --runThreadN  20 \
		--runMode genomeGenerate \
    	--genomeDir ${outputDir}/indices/STAR_genome_indices \
    	--genomeFastaFiles ${genome_fasta} \
		--sjdbGTFfile  ${genome_GTF} \
		--genomeSAindexNbases 13 \
    	--sjdbOverhang 65 && echo "Genome indices created" || echo "indices failed" >&2
		#Options:
		#Uses 20 threads, 
		#runmode to create the indices
		#path to output the indices files
		#path where fasta genome is (in this case genome is compressed so it is send via stdin with zcat, that allows for visualizing correctly compressed files)
		#Path to GTF (annotation of genome) file
		#Optimize the process using following formula: "log2(genome_length)/2 -1"
		#Last option is for optimizing segment length. Optimal value is reads_length -1. 
fi
}  2> >(tee -a $outputDir/indices/logs/index_STAR_error.log) > >(tee -a $outputDir/indices/logs/index_STAR_output.log)

#For every sample do:

while IFS= read -r sample; do

	#For each sample, creates a subdirectory just in case it does not exists previosly
	if ! [[ -e $outputDir/$sample ]]; then
        	echo " sample $sample directory does not exists, creating..."
        	mkdir $outputDir/$sample
	fi
	#For each sample's subdirectory, creates results and logs subdirectories:
	if ! [[ -e $outputDir/$sample/results ]]; then
        	echo "$outputDir/$sample/results directory does not exists, creating..."
        	mkdir $outputDir/$sample/results
    fi
	if ! [[ -e $outputDir/$sample/logs ]]; then
                echo "$outputDir/$sample/logs directory does not exists, creating..."
                mkdir $outputDir/$sample/logs
    fi
{
	rm -rf /tmp/STAR_tmp #Make sure temporal directory does not exist just before STAR starts.
	#All alignment process will redirect its outputs (standar and error)
	#Defining paired ends names
	frw_reads=${sample}${FRPattern}
	rvs_reads=${sample}${RRPattern}

	#Checks if reads are compressed or not
	if [[ $FRPattern =~ gz$ ]]; then
		comando="--readFilesCommand zcat"
	else
		comando=""
	fi

	#Alignemnt is carried out.
	echo "Starting STAR alignment"
	STAR --genomeDir $outputDir/indices/STAR_genome_indices \
		 --runThreadN 16 \
		 --readFilesIn $inputDir/$frw_reads $inputDir/$rvs_reads \
		 --outFileNamePrefix $outputDir/$sample/results/STAR/ \
		 --outSAMtype BAM SortedByCoordinate \
		 --outSAMunmapped Within \
		 --outSAMattributes Standard \
		 --outTmpDir /tmp/STAR_tmp \
		 --limitBAMsortRAM 16000000000 \
		 ${comando} && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed" >&2
	#STAR OPTIONS:
	#Path to indices created before
	#20 threads allowed
	#Path to fwd and reverse files
	#output files are BAM sortedByCoordinatte (needed for featurecounts)
	#--outSAMunmapped Within means that reads not mapped to the genome are still printed in the BAM output file (with this option we can still make more quality controls such as % of unmapped reads...)
	#--outSAMattributes Standard: Attributes in BAM file are the standard.
	#--outTmpDir to specify a directory for temporal files STAR uses, this line is commonly optional but obligatory when using WSL where normal output are in WINDOWS DISKs.
	#--limitBAMsortRAM limits RAM usage while sorting BAM files (in this case to aprox 16GB)
	# ${comando} can be either "--readFilesCommand zcat" or nothing. The first allows STAR to read compressed files.

} 2> >(tee -a ${outputDir}/${sample}/logs/${sample}_alignment_error.log) > >(tee -a ${outputDir}/${sample}/logs/${sample}_alignment_output.log)

done < $sample_list

echo "Alignment completed"
exit 0
