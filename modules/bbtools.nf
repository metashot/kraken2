nextflow.enable.dsl=2


process deinterleave {      
    tag "${id}"

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id), path("deint*.fastq.gz"), emit: reads

    script:
    task_memory_GB = task.memory.toGiga()
    """
    reformat.sh \
        -Xmx${task_memory_GB}g \
        in=$reads \
        out1=deint_1.fastq.gz \
        out2=deint_2.fastq.gz \
        t=1
    """
}

process raw_reads_stats {   
    tag "${id}"

    publishDir "${params.outdir}/raw_reads_stats/${id}" , mode: 'copy'

    input:
    tuple val(id), path(reads)

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
        gcbins=auto \
        threads=${task.cpus}
    """
}
