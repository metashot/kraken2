#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { deinterleave; raw_reads_stats } from './modules/bbtools'
include { kraken2; bracken; combine_kraken2_reports; combine_kraken2_mpa; combine_bracken; combine_bracken_reports; combine_bracken_mpa} from './modules/kraken'


workflow {
    Channel
        .fromFilePairs( params.reads, size: (params.single_end || params.interleaved) ? 1 : 2 )
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}." }
        .set { reads_ch }

    kraken2_db = file(params.kraken2_db, type: 'dir', checkIfExists: true)

    Channel
        .fromList( ['D', 'P', 'C', 'O', 'F', 'G', 'S'] )
        .set { bracken_levels_ch } 

    if (params.interleaved) {
        deinterleave(reads_ch)
        deint_ch = deinterleave.out.reads
    } else {
        deint_ch = reads_ch
    }

    raw_reads_stats(deint_ch)

    kraken2(deint_ch, kraken2_db)
    
    combine_kraken2_reports(kraken2.out.report.map { row -> row[1] }.collect())
    combine_kraken2_mpa(kraken2.out.mpa.map { row -> row[1] }.collect())

    bracken(
        bracken_levels_ch.combine(kraken2.out.report),
        kraken2_db
    )

    combine_bracken(bracken_out.bracken.groupTuple())
    combine_bracken_reports(bracken_out.report.groupTuple())
    combine_bracken_mpa(bracken_out.mpa.groupTuple())
}
