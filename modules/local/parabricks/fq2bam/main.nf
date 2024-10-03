process PARABRICKS_FQ2BAM {
    tag "$meta.id"
    label 'process_high'

    accelerator 1

    container "nvcr.io/nvidia/clara/clara-parabricks:4.3.0-1"

    input:
    tuple val(meta), val(read_groups), path ( r1_fastq, stageAs: "?/*"), path ( r2_fastq, stageAs: "?/*"), path(interval_file)
    tuple path(fasta), path(fai)
    path index 
    path known_sites

    output:
    tuple val(meta), path("*.bam")                , emit: bam
    tuple val(meta), path("*.bai")                , emit: bai
    path "versions.yml"                           , emit: versions
    path "qc_metrics", optional:true              , emit: qc_metrics
    path("*.table"), optional:true                , emit: bqsr_table
    path("duplicate-metrics.txt"), optional:true  , emit: duplicate_metrics

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "Parabricks module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def in_fq_command = meta.single_end ? "--in-se-fq $r1_fastq" : "--in-fq $r1_fastq $r2_fastq"
    def known_sites_command = known_sites ? (known_sites instanceof List ? known_sites.collect { "--knownSites $it" }.join(' ') : "--knownSites ${known_sites}") : ""
    def known_sites_output = known_sites ? "--out-recal-file ${prefix}.table" : ""
    def interval_file_command = interval_file ? (interval_file instanceof List ? interval_file.collect { "--interval-file $it" }.join(' ') : "--interval-file ${interval_file}") : ""


    """

    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`
    mv $fasta \$INDEX

    pbrun \\
        fq2bam \\
        --ref \$INDEX \\
        $in_fq_command \\
        --read-group-sm $meta.id \\
        --out-bam ${prefix}.bam \\
        $known_sites_command \\
        $known_sites_output \\
        $interval_file_command \\
        --num-gpus $task.accelerator.request \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
            pbrun: \$(echo \$(pbrun version 2>&1) | sed 's/^Please.* //' )
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "Parabricks module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def in_fq_command = meta.single_end ? "--in-se-fq $r1_fastq" : "--in-fq $r1_fastq $r2_fastq"
    def known_sites_command = known_sites ? (known_sites instanceof List ? known_sites.collect { "--knownSites $it" }.join(' ') : "--knownSites ${known_sites}") : ""
    def known_sites_output = known_sites ? "--out-recal-file ${prefix}.table" : ""
    def interval_file_command = interval_file ? (interval_file instanceof List ? interval_file.collect { "--interval-file $it" }.join(' ') : "--interval-file ${interval_file}") : ""

    def metrics_output_command = args = "--out-duplicate-metrics duplicate-metrics.txt" ? "touch duplicate-metrics.txt" : ""
    def known_sites_output_command = known_sites ? "touch ${prefix}.table" : ""
    def qc_metrics_output_command = args = "--out-qc-metrics-dir qc_metrics " ? "mkdir qc_metrics && touch qc_metrics/alignment.txt" : ""
    """
    touch ${prefix}.bam
    touch ${prefix}.bam.bai
    $metrics_output_command
    $known_sites_output_command
    $qc_metrics_output_command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
            pbrun: \$(echo \$(pbrun version 2>&1) | sed 's/^Please.* //' )
    END_VERSIONS
    """
}
