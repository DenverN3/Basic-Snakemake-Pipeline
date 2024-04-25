BASE_DIR = "/Users/denverncube/Desktop/CHOP"

rule all:
    input:
        f"{BASE_DIR}/snpEff_annotated_variants.vcf",
        f"{BASE_DIR}/multiqc_report.html",
        f"{BASE_DIR}/bam_stats.tsv",
        f"{BASE_DIR}/bam_coverage.tsv"

rule fastqc:
    input:
        r1=f"{BASE_DIR}/sample_R1.fq.gz",
        r2=f"{BASE_DIR}/sample_R2.fq.gz"
    output:
        r1_html=f"{BASE_DIR}/sample_R1_fastqc.html",
        r1_zip=f"{BASE_DIR}/sample_R1_fastqc.zip",
        r2_html=f"{BASE_DIR}/sample_R2_fastqc.html",
        r2_zip=f"{BASE_DIR}/sample_R2_fastqc.zip"
    threads: 2
    shell:
        f"""
        fastqc {{input.r1}} {{input.r2}} --outdir {BASE_DIR}
        """

rule multiqc:
    input:
        html1=f"{BASE_DIR}/sample_R1_fastqc.html",
        html2=f"{BASE_DIR}/sample_R2_fastqc.html"
    output:
        html=f"{BASE_DIR}/multiqc_report.html"
    shell:
        f"""
        multiqc {{input}} -o {{output}}
        """

rule alignment:
    input:
        r1=f"{BASE_DIR}/sample_R1.fq.gz",
        r2=f"{BASE_DIR}/sample_R2.fq.gz",
        ref=f"{BASE_DIR}/human_g1k_v37.fasta"
    output:
        bam=f"{BASE_DIR}/sorted_aligned_reads.bam",
        bai=f"{BASE_DIR}/sorted_aligned_reads.bam.bai"
    threads: 4
    shell:
        f"""
        bwa mem -t {{threads}} {{input.ref}} {{input.r1}} {{input.r2}} | samtools view -bS - | samtools sort -o {{output.bam}} 
        samtools index {{output.bam}}
        """

rule add_read_groups:
    input:
        bam=f"{BASE_DIR}/sorted_aligned_reads.bam"
    output:
        bam_with_rg=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam"
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam_with_rg} \
            RGID=1 \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM=sample   
        """

rule index_bam_with_rg:
    input:
        bam_with_rg=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam"
    output:
        bam_index=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam.bai"
    shell:
        f"""  
        samtools index {{input}}  
        """

rule variant_calling:
    input:
        bam=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam",
        ref=f"{BASE_DIR}/human_g1k_v37.fasta",
        bed=f"{BASE_DIR}/roic_corrected.bed"
    output:
        vcf=f"{BASE_DIR}/raw_variants.vcf"
    threads: 8
    shell:
        f"""
        gatk --java-options '-Xmx16G -DGATK_STACKTRACE_ON_USER_EXCEPTION=true' HaplotypeCaller -R {{input.ref}} -I {{input.bam}} -O {{output.vcf}} -L {{input.bed}} -ERC GVCF --sample-name sample --native-pair-hmm-threads 5
        """

rule samtools_flagstat:
    input:
        bam=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam"
    output:
        tsv=f"{BASE_DIR}/bam_stats.tsv"
    shell: 
        f"""samtools flagstat {{input.bam}} > {{output}}"""


rule samtools_coverage:
    input:
        bam=f"{BASE_DIR}/sorted_aligned_reads_with_rg.bam"
    output:
        cov=f"{BASE_DIR}/bam_coverage.tsv"
    threads: 1
    shell:
        f"""samtools coverage {{input.bam}} -o {{output.cov}}"""

rule snpEff_annotation:
    input:
        vcf=f"{BASE_DIR}/raw_variants.vcf"
    output:
        vcf=f"{BASE_DIR}/snpEff_annotated_variants.vcf"
    params:
        snpEff_config="snpEff.config",
        genome_version="hg19"
    log:
        f"{BASE_DIR}/snpEff_annotation.log"
    threads: 4
    shell:
        f"""
        java -Xmx8g -jar /Users/denverncube/anaconda3/envs/TEST/share/snpeff-5.2-0/snpEff.jar hg19 {{input.vcf}} -c /Users/denverncube/anaconda3/envs/TEST/share/snpeff-5.2-0/snpEff.config -o vcf -stats {{output.vcf}}.stats.html > {{output.vcf}} 2> {{log}}
        """

