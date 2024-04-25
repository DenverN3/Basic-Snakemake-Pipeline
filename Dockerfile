# Use an official Python runtime as a parent image
FROM ubuntu:20.04

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the Snakemake file into the container and gatk into container to bypass downloading from github
COPY Snakefile /usr/src/app/Snakefile
COPY gatk-4.5.0.0 /usr/src/app/gatk-4.5.0.0

#copy relevant files into the containter
COPY sample_R1.fq.gz /usr/src/app/sample_R1.fq.gz
COPY sample_R2.fq.gz /usr/src/app/sample_R2.fq.gz
COPY human_g1k_v37.fasta /usr/src/app/human_g1k_v37.fasta
COPY roic_corrected.bed /usr/src/app/roic_corrected.bed

#INSTALL dependencies
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get update && apt-get install -y \
        wget \
        bzip2 \
        gcc \
        make \
        default-jdk \
        unzip \
        curl

# Install SnpEff
RUN wget https://snpeff.blob.core.windows.net/versions/snpEff_latest_core.zip && \
    unzip snpEff_latest_core.zip && \
    rm snpEff_latest_core.zip
# Install any needed packages specified in requirements.txt
RUN apt-get update && \
    apt-get install -y snakemake

#Install fastQC from source
RUN wget -q https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip -O /tmp/fastqc.zip && \
    unzip /tmp/fastqc.zip -d /opt/ && \
    chmod +x /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm /tmp/fastqc.zip

# Install Picard
RUN curl -fsSL https://github.com/broadinstitute/picard/releases/download/2.27.1/picard.jar -o /usr/local/bin/picard.jar && \
    chmod +x /usr/local/bin/picard.jar

# Update the package list
RUN apt-get update

# Install python3 and pip3
RUN apt-get install -y python3 python3-pip

# Install MultiQC
RUN pip3 install multiqc

# Install BWA, SAMtools, Picard, and GATK using system packages or binaries
RUN apt-get install -y bwa samtools
RUN wget https://github.com/broadinstitute/picard/releases/download/2.27.1/picard.jar -O /usr/local/bin/picard.jar
RUN chmod +x /usr/local/bin/picard.jar

#Set up environment variable to the GATK jar
ENV GATK_JAR=/usr/src/app/gatk-4.5.0.0/gatk-package-4.5.0.0-local.jar
# Copy the Snakemake workflow files into the container
COPY . /usr/src/app

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Set entrypoint to use Snakemake
ENTRYPOINT ["snakemake"]

# Default command that runs if no other command is specified
CMD ["all", "--cores", "5"]