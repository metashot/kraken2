# nf-kraken2-illumina

## Introduction
nf-kraken2-illumina is a workflow for the taxonomic classification of reads and
the abundance estimation of species in metagenomic samples.

- Input: single-end, paired-end (also interleaved) Illumina sequences (gzip
  and bzip2 compressed FASTQ also supported);
- Histogram text files of base frequency, quality scores, gc content, average
  quality and length are generated from input reads using
  [bbduk](https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbduk-guide/);
- Taxonomic classification using 
  [Kraken 2](http://ccb.jhu.edu/software/kraken2/index.shtml);
- Abundance estimation for each taxonomic level using
  [Bracken](http://ccb.jhu.edu/software/bracken/index.shtml);

## Kraken 2 / Braken databases
We suggest to use one of the Kraken 2 / Bracken databases available at 
https://benlangmead.github.io/aws-indexes/k2.

## Usage

    nextflow run nf-kraken2-illumina \
        data/*{1,2}.fastq.gz \
        --kraken2_db /path/to/kraken2_db \
        --outdir results
