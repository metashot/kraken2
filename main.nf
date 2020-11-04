#!/usr/bin/env nextflow

Channel
    .fromFilePairs( params.reads, size: (params.single_end || params.interleaved) ? 1 : 2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}." }
    .set { raw_reads_deinterleave_ch }

kraken2_db = file(params.kraken2_db, type: 'dir')

Channel
    .fromList( ['D', 'P', 'C', 'O', 'F', 'G', 'S'] )
    .set { levels_bracken_tmp_ch } 

/*
 * Step 0. Deinterleave paired reads
 */
if (params.interleaved) {
    process deinterleave {      
        tag "${id}"

        input:
        tuple val(id), path(reads) from raw_reads_deinterleave_ch

        output:
        tuple val(id), path("read_*.fastq.gz") into raw_reads_stats_ch, raw_reads_kraken2_ch

        script:
        task_memory_GB = task.memory.toGiga()
        
        """
        reformat.sh \
            -Xmx${task_memory_GB}g \
            in=$reads \
            out1=read_1.fastq.gz \
            out2=read_2.fastq.gz \
            t=1
        """
    }
} else {
    raw_reads_deinterleave_ch.into { raw_reads_stats_ch; raw_reads_kraken2_ch }
}

/*
 * Step 1. Raw reads histograms
 */
process raw_reads_stats {   
    tag "${id}"

    publishDir "${params.outdir}/raw_reads_stats/${id}" , mode: 'copy'

    input:
    tuple val(id), path(reads) from raw_reads_stats_ch

    output:
    path "*hist.txt"

    script:
    task_memory_GB = task.memory.toGiga()
    input = params.single_end ? "in=\"$reads\"" : "in1=\"${reads[0]}\" in2=\"${reads[1]}\""
    """
    bbduk.sh \
        -Xmx${task_memory_GB}g \
        $input \
        bhist=bhist.txt \
        qhist=qhist.txt \
        gchist=gchist.txt \
        aqhist=aqhist.txt \
        lhist=lhist.txt \
        gcbins=auto
    """
}

/*
 * Step 2. Kraken2
 */
process kraken2 {
    tag "${id}"

    publishDir "${params.outdir}/kraken2/${id}" , mode: 'copy'

    input:
    tuple val(id), path(reads) from raw_reads_kraken2_ch
    path kraken2_db from kraken2_db
    
    output:
    tuple val(id), path("kraken2.report") into kraken2_report_bracken_tmp_ch
    path "kraken2.output"

    script:
    input = params.single_end ? "\"$reads\"" :  "--paired \"${reads[0]}\" \"${reads[1]}\""
    report_zero_counts = params.report_zero_counts ? "--report-zero-counts" : ""
    """
    kraken2 \
        --db $kraken2_db \
        --threads ${task.cpus} \
        $report_zero_counts \
        --report kraken2.report \
        $input \
        > kraken2.output
    """
}

levels_bracken_tmp_ch
    .combine(kraken2_report_bracken_tmp_ch)
    .set { kraken2_report_bracken_ch }

/*
 * Step 3.a Bracken
 */
process bracken {
    tag "${level}-${id}"

    publishDir "${params.outdir}/bracken/${id}" , mode: 'copy' ,
        saveAs:  { filename -> "bracken_${level}.output" }

    input:
    tuple val(level), val(id), path(kraken2_report) from kraken2_report_bracken_ch
    path kraken2_db from kraken2_db
    
    output:
    tuple val(level), path("${id}.bracken") into bracken_output_combine_bracken_tmp_ch
    
    script:
    """
    bracken \
        -d $kraken2_db \
        -r ${params.read_len} \
        -l $level \
        -i $kraken2_report \
        -o ${id}.bracken 
    """
}

bracken_output_combine_bracken_tmp_ch
    .groupTuple()
    .set { bracken_output_combine_bracken_ch }

/*
 * Step 3.b Combine bracken outputs
 */
process combine_bracken {
    tag "${level}"

    publishDir "${params.outdir}/bracken_combined" , mode: 'copy'

    input:
    tuple val(level), path(bracken_outputs) from bracken_output_combine_bracken_ch

    output:
    path "bracken_${level}.output"
    
    script:
    """
    python /usr/local/bracken/analysis_scripts/combine_bracken_outputs.py \
        --files $bracken_outputs \
        --output bracken_${level}.output
    """
}
