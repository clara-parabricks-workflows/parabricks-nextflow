#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { PARABRICKS_FQ2BAM } from './modules/fq2bam/main'

workflow {

    PARABRICKS_FQ2BAM (
        params.inputFASTQ_1,
        params.inputFASTQ_2,
        params.inputRef,
        params.inputKnownSitesVCF
    )

}