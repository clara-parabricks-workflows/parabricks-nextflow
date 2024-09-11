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
include { PARABRICKS_DEEPVARIANT } from './modules/deepvariant/main'

def model_file = params.model_file ? file(params.model_file, checkIfExists: true) : [] 
def interval_bed = params.interval_bed ? file(params.interval_bed, checkIfExists: true) : [] 

// Check input path parameters to see if they exist
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

workflow {

    ch_genome = [params.fasta, params.fasta_fai, params.genome_file, params.chrom_sizes, params.genome_dict]

    // parse input samplesheet
    Channel.value(ch_input)
            .splitCsv ( header:true, sep:',' )
            .set { sheet }

    // create ch_fastq
    ch_fastq = sheet.map { row -> [[row.sample], row] }
                .groupTuple()
                .map { meta, rows ->
                    [rows, rows.size()]
                }
                .transpose()
                .map { row, numLanes ->
                    create_fastq_channel(row + [num_lanes:numLanes])
                }

    // fastq -> bam (fq2bam)
    PARABRICKS_FQ2BAM (
        ch_fastq,
        params.bwa_index,
        ch_genome,
        params.inputKnownSitesVCF
    )

    // get bam ch
    ch_bam_bai = PARABRICKS_FQ2BAM.out.bam_bai

    // bam -> vcf (deepvariant)
    PARABRICKS_DEEPVARIANT (
        ch_bam_bai,
        ch_genome,
        model_file,
        interval_bed
    )
}

def create_fastq_channel(LinkedHashMap row) {

    def fields = [
        'r1_fastq': ['meta': [:], 'read_num': 'R1'],
        'r2_fastq': ['meta': [:], 'read_num': 'R2']
    ]

    // This is the meta variable that gets passed to the processes 
    def meta = [
        id: row.sample,
        sample: row.sample,
        prefix: row.sample + "__" + row.read_group,
        read_group: row.read_group,
        platform: row.platform,
        gender: row.gender,
        num_lanes: row.num_lanes,
        single_end: false
    ]

    // Add paths of the fastq files to the meta map
    def fastq_files = []

    fields.each { key, value ->
        if (row[key]) {
            def file_path = file(row[key])
            if (!file_path.exists()) {
                error("ERROR: Please check input samplesheet -> ${value.read_num} FastQ file does not exist!\n${row[key]}")
            }
            fastq_files << file_path
        }
    }

    // Determine if the read is single-ended
    if (!row.r2_fastq) {
        meta.single_end = true
    }

    // Return the meta and fastq files list
    return [meta, fastq_files]
}