# kraken2

metashot/kraken2 is a workflow for the taxonomic classification of reads and the
abundance estimation of species in metagenomic samples.

- [MetaShot Home](https://metashot.github.io/)

## Main features

- Input: single-end, paired-end (also interleaved) Illumina sequences (gzip and
  bzip2 compressed FASTA or FASTQ also supported);
- Histogram text files (for each input sample) of base frequency, quality
  scores, GC content, average quality and length are generated from input reads
  using
  [bbduk](https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbduk-guide/);
- Taxonomic classification using 
  [Kraken 2](http://ccb.jhu.edu/software/kraken2/index.shtml);
- Abundance estimation for each taxonomic level using
  [Bracken](http://ccb.jhu.edu/software/bracken/index.shtml).

## Quick start

1. Install Docker (or Singulariry) and Nextflow (see
   [Dependences](https://metashot.github.io/#dependencies));
1. Download and extract/unzip a Kraken 2 / Bracken database available at
   https://benlangmead.github.io/aws-indexes/k2;
1. Start running the analysis:
   
  ```bash
  nextflow run metashot/kraken2 \
    --reads '*_R{1,2}.fastq.gz' \
    --kraken2_db k2db \
    --read_len 100 \
    --outdir results
  ```

## Parameters
See the file [`nextflow.config`](`nextflow.config) for the complete list of
parameters.

## Output
The files and directories listed below will be created in the `results` directory
after the pipeline has finished.

### Main outputs
- `kraken2`: kraken2 outputs (including the report file) for each input
  sample;
- `bracken_combined`: single text tab-delimined file with estimated
  abundance across all samples for each taxonomic level.

### Secondary outputs
- `raw_reads_stats`: base frequency, quality scores, gc content, average
  quality and length for each input sample;
- `bracken`: bracken output for each taxonomic level (from Domain `D` to
  Species `S`) for each sample.

## Memory requirements
Kraken 2 requires enough free memory to hold the index in RAM. If the index size
is 47 GB (standard database, 2020/09/19) you will need slightly more  than that
free in RAM (set the `--max_memory` parameter to `64.GB`).

Please refer to [System
requirements](https://metashot.github.io/#system-requirements) for the complete
list of system requirements options.