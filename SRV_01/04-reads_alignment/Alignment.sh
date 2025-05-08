#!/bin/bash
#Script name: RNA-Seq Alignment with Multiple Aligners and Output Management
#Author: Jaime Salama García
#Date: 23/04/2025
#Purpose: A Bash script that automates RNA-Seq alignment for multiple samples, allowing users to choose between
# popular aligners like STAR, HISAT2, or Bowtie2. The script should process a batch of paired-end FASTQ files, manage outputs,
# and ensure robust error handling.
#Usage: ./alignment_script.sh input_reads_dir _R1.fastq _R2.fastq genome/genome.fa genome/annotation.gtf STAR out_dir sample_list.txt
readonly VERSION="1.0.1"
# El script requiere estos argumentos, con las siguientes flags:
#1. -i Input Directory containing the FASTQ files
#2. -F Forward Read Suffix/Pattern (e.g., _R1.fastq or _1.fastq.gz)
#3. -R Reverse Read Suffix/Pattern (e.g., _R2.fastq or _2.fastq.gz)
#4. -f Genome Reference file (FASTA format)
#5. -g Genome Annotation file (GTF format)
#6. -a Aligner Tool (choose one: STAR, HISAT2, or Bowtie2)
#7. -o Output Folder where results will be saved
#8. -s Sample List: A file containing the base names of each sample (without the _R1 or _R2 part)
#-h displays help
#v displays version
readonly help_text="Usage: $(basename $0) -i input_reads_dir -F _R1.fastq -R _R2.fastq -f genome/genome.fa -g genome/annotation.gtf -a STAR -o out_dir -s sample_list.txt"
#Parssing arguments
while getopts "hvi:F:R:f:g:o:a:s:" opt; do
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
    	a) aligner_tool="$OPTARG" ;;
		s) sample_list="$OPTARG" ;;
    	?) echo "Invalid option or missing argument: $help_text" >&2
       		exit 1 ;;
	esac
done

if [[ -z "$inputDir" || -z $outputDir || -z $FRPattern || -z $RRPattern || -z $genome_fasta || -z $genome_GTF || -z $aligner_tool || -z $sample_list ]]; then
        echo "Invalid option or missing argument: $help_text" >&2
        exit 1
fi

#File validation:
#Genome fasta file
if ! [[ -s $genome_fasta ]]; then
	echo "error in Genome Reference file: $genome_fasta not found or is empty"
	exit 2
fi
#genome GTF file
if ! [[ -s $genome_GTF ]]; then
        echo "error in Genome Annotation file: $genome_GTF not found or is empty"
        exit 2
fi
#Input Directory
if ! [[ -s $inputDir && -d $inputDir]]; then
        echo "error in input directory: $inputDir not found, is empty or is not a directory"
        exit 2
fi
#sample list file
if ! [[ -s $sample_list ]]; then
        echo "error in sample list file: $sample_list not found or is empty"
        exit 2
fi


#Create output directory and subdirectories:
echo "Creating output directory..."

if ! [[ -e $outputDir ]]; then
	echo "Output directory does not exists, creating..."
	mkdir $outputDir
fi

if ! [[ -e $outputDir/indices ]]; then
	mkdir $outputDir/indices
fi

#Creating index of the selected aligner
{

case $aligner_tool in
	STAR)
		#Alignment will be carried out by STAR.
                #First, STAR need genome indices.
		echo "STAR selected, creating indices..."
                STAR --runThreadN  6 \
                --runMode genomeGenerate \
                --genomeDir $outputDir/indices/STAR_genome_indices \
                --genomeFastaFiles  $genome_fasta \
                --sjdbGTFfile  $genome_GTF \
                --sjdbOverhang 100 && echo "Genome indices created" || echo "indices failed" #Se puede poner longitud max de las reads -1; habria que comprobar la max length de las reads.
	;;
	HISAT2)
		echo "HISAT2 selected, creating indices..."
		#Index creation:
                hisat2-build $genome_fasta $outputDir/indices/HISAT2_genome_indices/genome_index
	;;
	Bowtie2)
		echo "Bowtie2 selected, creating indices..."
		#Index creation:
                bowtie2-build $genome_fasta $outputDir/indices/bowtie2_genome_indices/genome_index
	;;
	*)
		echo "$aligner_tool is not a valid aligner"
		exit 3
	;;
esac
}  >> $outputDir/indices/logs/index_${aligner_tool}_output.log 2>> $outputDir/indices/logs/index_${aligner_tool}_error.log

#Bucle que recorre la lista de samples.
while IFS= read -r sample; do
{
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
	#All alignment process will redirect its outputs (standar and error)
		#Defining paired ends names
		frw_reads=${sample}${FRPattern}
		rvs_reads=${sample}${RRPattern}
		if [[ $FRPattern =~ gz$ ]]; then
			comando="--readFilesCommand zcat"
			comprimido=1
		else
			comando=""
			comprimido=0
		fi

		#Choose selected aligner
		case $aligner_tool in
			STAR)
				#propper alignemnt is carried out.
				echo "Starting STAR alignment"
				STAR --genomeDir $outputDir/STAR_genome_indices/ \
					--runThreadN 6 \
					--readFilesIn $inputDir/$frw_reads $inputDir/$rvs_reads \
					--outFileNamePrefix $outputDir/$sample/results/STAR/ \
					--outSAMtype BAM SortedByCoordinate \
					--outSAMunmapped Within \
					--outSAMattributes Standard \
					--quantMode TranscriptomeSAM GeneCounts \
					$comando && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed"
			;;

			HISAT2)
				echo "Starting HISAT2 alignment"
				# HISAT2 alignment
                		case comprimido in
                                        1)
						hisat2 -x $outputDir/indices/HISAT2_genome_indices/genome_index \
						-1 <(zcat $inputDir/$frw_reads) \
						-2 <(zcat $inputDir/$rvs_reads) \
						-S $outputDir/$sample/results/HISAT2/HISAT2.sam && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed"
                                        ;;
                                        0)
						hisat2 -x $outputDir/indices/HISAT2_genome_indices/genome_index \
						-1 $inputDir/$frw_reads \
						-2 $inputDir/$rvs_reads \
						-S $outputDir/$sample/results/HISAT2/HISAT2.sam && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed"
                                        ;;
		        ;;

			Bowtie2)
				echo "Starting Bowtie2 alignment"
				#Bowtie2 alignment:
				case comprimido in
					1)
						bowtie2 \
  						-x $outputDir/indices/bowtie2_genome_indices/genome_index \
  						-1 <(zcat $inputDir/$frw_reads) \
 	 					-2 <(zcat $inputDir/$rvs_reads) \
  						-S $outputDir/$sample/results/bowtie2/alineamiento.sam \
  						-p 6 && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed"
					;;
					0)
						bowtie2 \
                                                -x $outputDir/indices/bowtie2_genome_indices/genome_index \
                                                -1 $inputDir/$frw_reads \
                                                -2 $inputDir/$rvs_reads \
                                                -S $outputDir/$sample/results/bowtie2/alineamiento.sam \
                                                -p 6 && echo "Alignment with sample $sample done" || echo "Alignment with sample $sample failed"
					;;
                        ;;

			*)
				echo "Aligner tool not valid"
				exit 3
			;;
		esac
} >> $outputDir/$sample/logs/${sample}_alignment_output.log 2>> $outputDir/$sample/logs/${sample}_alignment_error.log
done < $sample_list

echo "Alignment completed"
exit 0
