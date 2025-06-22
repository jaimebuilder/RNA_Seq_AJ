Online Github Repository: https://github.com/jaimebuilder/RNA_Seq_AJ 

This is a workflow for RNA-Seq designed by Jaime Salama García & Alberto Romero Lucas for a final work of the subject Programación para bioinformática of Grado en Biotécnología in UPM/Universidad Politécnica de Madrid

The workflow is divided in 6 steps, from 1-5 are bash scripts to be runned in a linux machine preferably in a conda environment that can be created as described later.
The last step (06-diffferential_analysis) consists of an R script in which all the analysis is done using some packages described in  the first part of the script.

You may manual download the scripts or use "git" to clone this repository. 

BEFORE RUNNING ANY BASH SCRIPT:

For creating the conda environment:

First install any conda distribution such us miniforge ( GitHub: https://github.com/conda-forge/miniforge/ )
Then run the following commands in the linux terminal:

#Commands:
conda create -n RNA_SEQ # it is possible to change "RNA_SEQ" for any name you of your preference
conda activate RNA_SEQ # Same name as before
mamba install sra-tools pigz fastqc multiqc fastp STAR subread # You can either use mamba or conda for installing 
#End of commands

Possible error istalling, be sure you have bioconda channel available in your conda installation. It can be added to your channels by the command:

#Commands:
conda config --add channels bioconda
#End of commands

After creating the environment and installing dependences, the conda environment is ready.
Always remember to activate the environment BEFORE running any bash script:

#Commands:
conda activate RNA_SEQ #In case you are not already in the environment. Make sure you use the same name as used in the previous commands
#End of commands

Brief explication of dependences:
sra-tools: a package for downloading data from NCBI database 
pigz: An alternative command for gzip that allows for multiple threads (Reducing the time needed for compression in multithreads machines)
fastqc: A program to make reports about the quality of the reads
multiqc: A program for visualizing all fastqc (or others) reports in a single report resuming all sample's data
fastp: A program from trimmming and filtering the reads before the alignment, allowing us to eliminate poor quality reads and trimming adapters
STAR: An spliced aligner, aigns the reads with the reference genome. 
subread: A package that contains featureCounts program, which we use to count hown many reads had aligned which each gene

AFTER CONDA ENVIRONMENT CREATION:

For each step of the process there is a subdirectory inside SRV_01 with the script and it might have some additionals files that scripts needs (at least in the online repository) with example's data.

Then we describe an example of an RNA_Seq analysis carried out using some raw data of the paper: RNA-Seq analysis of mung bean (Vigna radiata L.) roots shows differential gene expression and predicts regulatory pathways responding to taxonomically different rhizobia (Sughra Hakim et al.)   DOI: https://doi.org/10.1016/j.micres.2023.127451

Raw data is available in NCBI database: https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=658645

All the scripts will create a logs folder where you can find output and error logs.

EXAMPLE:

All the scripts will be executed from their respective subdirectory (like 00-raw_data)
Make sure every script has r-x (read and executable) permissions.



1. In 00-raw_data

In this step the scripts download all the files we would need during the workflow

command: bash Import_raw_data.sh -f SRR_samples_file.txt -d https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-61/plants/fasta/vigna_radiata/dna/Vigna_radiata.Vradiata_ver6.dna.toplevel.fa.gz -g https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-61/plants/gtf/vigna_radiata/Vigna_radiata.Vradiata_ver6.61.gtf.gz

Explication: 
-f SRR_samples_file.txt is the file that contains the SRR accessions of the samples, one per line.
-d url of the genome fasta
-g url of the genome GTF 

Estimated outputs: genome fasta and GTF in a subdirectory called genome_files and .fastq.gz files for each sample. In paired-end samples are divded in _1 _2.

2. In 01-pre_fastqc
This step is to evaluate the quality of the raw reads
command:  bash pre_fastqc.sh -i ../00-raw_data/ -o .

Explication: 

-i is the input directory, where reads are allocated, in this case ../00-raw_data, just where preivous script donwloaded the data. 
(This script will look for COMPRIMED files: .fastq.gz and paired-end _1 _2 )
-o is for the output directory, which will be this directory.

Estimated outputs:

a fastqc folder with .zip data and .html reports of each individual sample
a multiqc folder with a subfolder multiqc_data and .html global report 

3. In 02-trimming_filtering
This step is for filtering and trimming reads so we remain just the best quality reads without any adapter sequence that could compromise the analysis
command: bash trimming_filtering.sh -i ../00-raw_data/ -o . -f ../00-raw_data/SRR_samples_file.txt

Explication: 

-f is the same file as described in 00-raw_data 
-i is the directory with reads to input (in this case 00-raw_data)
-o nis the output to place trimmed and filtered reads (in this case this directory)

Estimated outputs:

samples fwd and reverse _cleaned
.html + .json reports of each paired-end sample (all reports could be merged with multiqc ina single report if wanted)

4. In 03-post_fastqc
This step is to evaluate the quality AFTER the filtering/trimming; which is estimated to be much better than 01. Is similar to the step 01.
command: bash post_fastqc.sh -i ../02-trimming_filtering/ -o .

Expliacation:

Sintaxis is the same as described in 01. In this case the input directory is where cleaned files are present (02-trimming_filtering)

Estimated outputs:

same outputs as described in 01.

5. In 04-reads_alignment
This step will align the cleaned reads to the genome. Itn requires 2-steps, first creating and index for the genome and second align each sample's reads to the genome.
command: bash Alignment.sh -i ../02-trimming_filtering/ -F _1_cleaned.fastq.gz -R _2_cleaned.fastq.gz -f ../00-raw_data/genome_files/Vigna_radiata.Vradiata_ver6.dna.toplevel.fa -g ../00-raw_data/genome_files/Vigna_radiata.Vradiata_ver6.61.gtf -o . -s ../00-raw_data/SRR_samples_file.txt

Explication:

-i Input Directory containing the FASTQ files (They can be either compressed or not, but all files the same)
-F Forward Read Suffix/Pattern (e.g., _R1.fastq or _1.fastq.gz) In this case is _1_cleaned.fastq.gz
-R Reverse Read Suffix/Pattern (e.g., _R2.fastq or _2.fastq.gz)
-f Genome Reference file (FASTA format) NOT COMPRESSED
-g Genome Annotation file (GTF format) NOT COMPRESSED
-o Output Folder where results will be saved. In this case is this directory
-s Sample List: A file containing the base names of each sample (without the _R1 or _R2 part)

Note: fastq files names should be exactly the same as joining the lines from -s File + Pattern (FWD or REV), for example: SRR12506729 + _1_cleaned.fastq.gz

Estimated outputs:

A folder called indices where is located a subfolder called STAR_genome_indices with all the index files STAR creates & a logs folder

A folder for each sample, inside this folder 2 subfolders being logs and results. INside results a subfolder called STAR will contain BAM files and other outputs STAR creates.

The path to BAM files (files sorted by coordinate of all mapped reads) will be: ./samplename/results/STAR/Aligned.sortedByCoord.out.bam (this path is recognised in next step)

6. In 05-counts-alignment:
This step consist in counting how many reads are aligned to each gene (without normalizing)

command: bash counts_alignment.sh -i ../04-reads_alignment/ -g ../00-raw_data/genome_files/Vigna_radiata.Vradiata_ver6.61.gtf

Explication:

-d input_directory. Directory that contains the results of the alignment. It SHOULD BE the same than the Output directory specified during the alingment. 
Note: the script automatically recognise the same output structure explained in step 04 so will first check for all folders named SRR* in the inpuut directory.
-g GTF file

Estimated outputs:

logs folder.
counts.txt : This is the important file containing all raw counts 
counts.txt.summary: A summary output of featureCounts with information like how many reads assigned or unassigned... 

7. In 06-differential_analysis

There is a .Rmd (R markdown) script with all the differential analysis carried out by R. You should execute the chunks to obtain some common plots. 
An html or PDF report could be obtained using the "knit" option.

For more understanding of the script check the comments inside.