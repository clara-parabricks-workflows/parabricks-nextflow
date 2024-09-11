process PARABRICKS_DEEPVARIANT {
    tag "$meta.id"
    accelerator 1

    input:
    tuple val(meta), path(input), path(input_index)
    tuple path(fasta), path(fai), path(genome_file), path(chrom_sizes), path(genome_dict)
    path model_file
    path interval_bed
    path proposed_variants

    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    tuple val(meta), path("*.log"), emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.suffix ? "${meta.id}${task.ext.suffix}" : "${meta.id}"
    def model_file_option = model_file ? "--pb-model-file $model_file" : ""
    def proposed_variants_option = proposed_variants ? "--proposed-variants $proposed_variants" : ""
    def interval_file_option = interval_bed ? "--interval-file $interval_bed" : ""
    
    """
    logfile=run.log
    exec > >(tee \$logfile)
    exec 2>&1

    echo "pbrun deepvariant --ref $fasta --in-bam $input --out-variants ${prefix}.vcf --num-gpus $task.accelerator.request ${interval_file_option} ${proposed_variants_option} ${model_file_option} $args"

    pbrun \\
        deepvariant \\
        --ref $fasta \\
        --in-bam $input \\
        --out-variants ${prefix}.output.vcf \\
        --num-gpus $task.accelerator.request \\
        ${interval_file_option} \\
        ${proposed_variants_option} \\
        ${model_file_option} \\
        $args
    """
}
