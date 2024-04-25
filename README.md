# Basic-Snakemake-Pipeline

This is a basic snakemake pipeline that allows you to do simple variant calling with GATK with a paired end fast data. I used it for a test that I was running on some sample data. 
The basic tools used here are: 
1. Fastqc for QC data
2. MultiQC for multiqc report generation
3. BWA for alignment
4. Picard for read group correction (you can take this out if your BAM files have read group specified, mine did not so I had to add them)
5. Samtools for sorting and indexing BAM files
6. GATK for variant calling
7. snpEff for variant annotation.

To enable portability of this pipeline, I also built a docker file that allows you to install all these tools in a custom docker container and enable deployment of the pipeline in a cloud or HPC environment. 
