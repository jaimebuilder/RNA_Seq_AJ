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
mamba install sra-tools pigz fastqc multiqc fastp STAR subread # You can either use mamba or conda for installing 
#End of commands

Possible error istalling, be sure you have bioconda channel available in your conda installation. It can be added to your channels by the command:

#Commands:
conda config --add channels bioconda
#End of commands

After creating the environment and installing dependences, the conda environment is ready, you need to activate the environment BEFORE running any bash script:

#Commands:
conda activate RNA_SEQ #Make sure you use the same name as used in the previous commands
#End of commands

Brief explication of dependences:
sra-tools: a package for downloading data from NCBI database 
pigz: An alternative command for gunzip that allows for multiple threads (Reducing the time needed for compression in multithreads machines)
fastqc: A program to make reports about the quality of the reads
multiqc: A program for visualizing all fastqc (or others) reports in a single report resuming all sample's data
fastp: A program from trimmming and filtering the reads before the alignment, allowing us to eliminate poor quality reads and trimming adapters
STAR: An spliced aligner, aigns the reads with the reference genome. 
subread: A package that contains featureCounts program, which we use to count hown many reads had aligned which each gene

AFTER CONDA ENVIRONMENT CREATION:

For each step of the process there is a subdirectory inside SRV_01 with the script and it might have some additionals files that scripts needs (at least in the online repository) with example's data.

Then we describe an example of an RNA_Seq analysis carried out using some raw data of the paper: RNA-Seq analysis of mung bean (Vigna radiata L.) roots shows differential gene expression and predicts regulatory pathways responding to taxonomically different rhizobia (Sughra Hakim et al.)   DOI: https://doi.org/10.1016/j.micres.2023.127451

Raw data is available in NCBI database: https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=658645

EXAMPLE:





