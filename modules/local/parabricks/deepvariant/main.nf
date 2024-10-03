process PARABRICKS_DEEPVARIANT {
    tag "$meta.id"
    label 'gpu'

    accelerator = 4 //, type: 'nvidia-tesla-k80'
    cpus = 48
    memory = 192.GB
    time = 1.h
    maxRetries = 3
    
    container "nvcr.io/nvidia/clara/clara-parabricks:4.3.0-1"

    input:
    tuple val(meta), path(bam), path(bai), path(interval_file)
    tuple path(fasta), path(fai)
    path model_file
    path proposed_variants


    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "Parabricks module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_file = args =~ "gvcf" ? "${prefix}.g.vcf" : "${prefix}.vcf"
    def interval_file_command = interval_file ? interval_file.collect{"--interval-file $it"}.join(' ') : ""
    def proposed_variants_option = proposed_variants ? "--proposed-variants $proposed_variants" : ""
    def model_file_option = model_file ? "--pb-model-file $model_file" : ""


    """

    pbrun \\
        deepvariant \\
        --ref $fasta \\
        --in-bam $bam \\
        --out-variants $output_file \\
        $interval_file_command \\
        --num-gpus $task.accelerator.request \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
            pbrun: \$(echo \$(pbrun version 2>&1) | sed 's/^Please.* //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_file = args =~ "gvcf" ? "${prefix}.g.vcf" : "${prefix}.vcf"
    """
    touch $output_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
            pbrun: \$(echo \$(pbrun version 2>&1) | sed 's/^Please.* //' )
    END_VERSIONS
    """
}
