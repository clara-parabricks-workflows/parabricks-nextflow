process PARABRICKS_DEEPVARIANT {
    tag "$meta.id"
    accelerator 1

    input:
    tuple val(meta), path(input), path(input_index)
    tuple path(fasta), path(fai), path(genome_file), path(chrom_sizes), path(genome_dict)
    path model_file
    path interval_bed

    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    tuple val(meta), path("*.log"), emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.suffix ? "${meta.id}${task.ext.suffix}" : "${meta.id}"
    def interval_file_option = interval_bed ? interval_bed.collect{"--interval-file $it"}.join(' ') : ""
    def model_command = model_file ? "--pb-model-file $model_file" : ""
    
    // def copy_index_command = input_index ? "cp -L $input_index `readlink -f $input`.bai" : ""
    """
    logfile=run.log
    exec > >(tee \$logfile)
    exec 2>&1

    echo "pbrun deepvariant --ref $fasta --in-bam $input --out-variants ${prefix}.vcf --num-gpus $task.accelerator.request ${interval_file_option} ${model_command} $args"

    pbrun \\
        deepvariant \\
        --ref $fasta \\
        --in-bam $input \\
        --out-variants ${prefix}.output.vcf \\
        --num-gpus $task.accelerator.request \\
        ${interval_file_option} \\
        ${model_command} \\
        $args
    """
}
