#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Pull in igenomes
params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.fasta_fai = "${params.fasta}.fai"
params.bwa_index = WorkflowMain.getGenomeAttribute(params, 'bwa')

log.info """\
======================================================
         P A R A B R I C K S - N E X T F L O W 
======================================================
samplesheet: ${params.input}
outdir: ${params.outdir}
known_sites: ${params.known_sites}
interval_bed: ${params.interval_bed}
proposed_variants: ${params.proposed_variants}
model_file: ${params.model_file}
fasta: ${params.fasta}
fasta_fai: ${params.fasta_fai}
bwa_index: ${params.bwa_index}

"""

include { PARABRICKS_FQ2BAM } from './modules/local/parabricks/fq2bam/main'
include { PARABRICKS_DEEPVARIANT } from './modules/local/parabricks/deepvariant/main'

def known_sites = params.known_sites ? file(params.known_sites, checkIfExists: true) : [] 
def model_file = params.model_file ? file(params.model_file, checkIfExists: true) : [] 
def proposed_variants = params.proposed_variants ? file(params.proposed_variants, checkIfExists: true) : [] 

// Check input path parameters to see if they exist
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

workflow {

    ch_versions = Channel.empty()

    ch_genome = [params.fasta, params.fasta_fai]
    
    // load samplesheet
    Channel.value(ch_input)
        .splitCsv ( header:true, sep:',' )
        .set { sheet }

    // count lanes/rows per sample
    ch_fastq = sheet.map { row -> [[row.sample], row] }
        .groupTuple()
        .map { meta, rows ->
            [rows, rows.size()]
        }
        .transpose()
        .map { row, numLanes ->
            create_fastq_channel(row + [num_lanes:numLanes])
        }
    
    // collapse by sample, add interval_bed to ch
    ch_fastq
    .map { meta, r1_fastq, r2_fastq ->
        grouped_id = meta.sample
        grouped_prefix = meta.id
        grouped_num_lanes = meta.num_lanes
        grouped_meta = [id: grouped_id, prefix: grouped_prefix, read_group: grouped_id, num_lanes: grouped_num_lanes]
        
        return [grouped_meta, meta, r1_fastq, r2_fastq]
    }
    .groupTuple()
    .map { grouped_meta, meta, r1_fastq, r2_fastq ->
        // Add the single interval_bed after grouping
        def interval_file = params.interval_bed ? file(params.interval_bed, checkIfExists: true) : [] 

        return [grouped_meta, meta, r1_fastq, r2_fastq, interval_file]
    }
    .set { ch_grouped_fastq }

    // fastq -> bam (fq2bam)
    PARABRICKS_FQ2BAM (
        ch_grouped_fastq,
        ch_genome,
        params.bwa_index,
        known_sites
    )

    // construct bam_bai ch, add interval_bed to ch
    ch_bam_bai = PARABRICKS_FQ2BAM.out.bam_bai
        .map {meta, bam, bai ->
            def interval_file = params.interval_bed ? file(params.interval_bed, checkIfExists: true) : [] 
            return [meta, bam, bai, interval_file]
        }
        .set { ch_bam_bai_interval }
    
    // bam -> vcf (deepvariant)
    PARABRICKS_DEEPVARIANT (
        ch_bam_bai_interval,
        ch_genome,
        model_file,
        proposed_variants
    )

    // add the bgzip + tabix of the produced vcf/gvcf
    //

    // multi qc 
    // make issue on multiqc repo, to push through module
    

}

def create_fastq_channel(LinkedHashMap row) {

    def meta = [
        id: row.sample,
        sample: row.sample,
        prefix: row.sample + "__" + row.read_group,
        read_group: row.read_group,
        platform: row.platform,
        gender: row.gender,
        num_lanes: row.num_lanes,
        single_end: false  // Default to paired-end
    ]
    
    def fields = [
        'r1_fastq': ['meta': [:], 'read_num': 'R1'],
        'r2_fastq': ['meta': [:], 'read_num': 'R2'],
        'fastq_1': ['meta': [:], 'read_num': 'R1'],
        'fastq_2': ['meta': [:], 'read_num': 'R2']
    ]

    // Add paths of the fastq files to the meta map
    def fastq_files = []

    fields.each { key, value ->
        if (row[key]) {
            def file_path = file(row[key])
            if (!file_path.exists()) {
                error("ERROR: Please check input samplesheet -> ${value.read_num} FastQ file does not exist!\n${row[key]}")
            }
        }
    }

    // Set r1_fastq and r2_fastq explicitly
    def r1_fastq = null
    def r2_fastq = null
    
    // Validate R1 fastq file
    if (row.r1_fastq || row.fastq_1) {
        r1_fastq = file(row.r1_fastq ? row.r1_fastq : row.fastq_1)
        if (!r1_fastq.exists()) {
            error("ERROR: Please check input samplesheet -> R1 FastQ file does not exist!\n${r1_fastq}")
        }
    } else {
        error("ERROR: R1 FastQ file is required but not found in the samplesheet for sample ${row.sample}")
    }

    // Validate R1 fastq file
    if (row.r2_fastq || row.fastq_2) {
        r2_fastq = file(row.r2_fastq ? row.r2_fastq : row.fastq_2)
        if (!r2_fastq.exists()) {
            error("ERROR: Please check input samplesheet -> R2 FastQ file does not exist!\n${r2_fastq}")
        }
    } else {
        error("ERROR: R2 FastQ file is required but not found in the samplesheet for sample ${row.sample}")
    }

    // Return the meta and the explicit r1 and r2 fastq files
    return [meta, r1_fastq, r2_fastq]
}