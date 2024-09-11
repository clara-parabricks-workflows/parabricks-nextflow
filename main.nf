#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Pull in igenomes
params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.fasta_fai = WorkflowMain.getGenomeAttribute(params, 'fasta_fai')
params.fasta_dir = WorkflowMain.getGenomeAttribute(params, 'fasta_dir')
params.genome_file = WorkflowMain.getGenomeAttribute(params, 'genome_file')
params.genome_dict = WorkflowMain.getGenomeAttribute(params, 'genome_dict')
params.chrom_sizes = WorkflowMain.getGenomeAttribute(params, 'chrom_sizes')
params.bwa_index = WorkflowMain.getGenomeAttribute(params, 'bwa')

include { PARABRICKS_FQ2BAM } from './modules/fq2bam/main'

workflow {

    ch_genome = [params.fasta, params.fasta_fai, params.genome_file, params.chrom_sizes, params.genome_dict]

    PARABRICKS_FQ2BAM (
        params.inputFASTQ_1,
        params.inputFASTQ_2,
        params.bwa_index,
        ch_genome,
        params.inputKnownSitesVCF
    )

}