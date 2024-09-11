process PARABRICKS_FQ2BAM {
    tag "$meta.id"
    accelerator 1

    input:
    tuple val(meta), path(reads)
    path index 
    tuple path(fasta), path(fai), path(genome_file), path(chrom_sizes), path(genome_dict)
    path known_sites
    path interval_bed

    output:
    tuple val(meta), path("*.bam"), path("*.bai"), emit: bam_bai
    tuple val(meta), path("*.log"), emit: log
    tuple val(meta), path("*.txt"), emit: recal 
    tuple val(meta), path("qc_metrics/"), emit: qc_metrics

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = meta.prefix ? "${meta.prefix}" : "${meta.id}"
    def read_group = meta.read_group ? "${meta.read_group}" : "RG"
    def platform = meta.platform ? "${meta.platform}" : "PL"
    def platform_unit = meta.read_group ? "${meta.read_group}" : "RG"
    def sample = meta.sample ? "${meta.sample}" : "SM"
    def read_group_string = "@RG\\tID:$read_group\\tLB:$sample\\tPL:$platform\\tSM:$sample\\tPU:$platform_unit"

    def in_fq_command = meta.single_end ? "--in-se-fq $reads \"$read_group_string\"" : "--in-fq $reads \"$read_group_string\""
    def known_sites_option = known_sites ? "--knownSites $known_sites --out-recal-file ${prefix}.recal.txt" : ""
    def interval_file_option = interval_bed ? "--interval-file $interval_bed" : ""
    def out_qc_metrics_option = "--out-qc-metrics-dir qc_metrics"

    """
    logfile=run.log
    exec > >(tee \$logfile)
    exec 2>&1

    INDEX=`find -L ./ -name "*.amb" | sed 's/.amb//'`
    # index and fasta need to be in the same dir as files and not symlinks
    # and have the same base name for pbrun to function
    # here we copy the index into the staging dir of fasta

    FASTA_PATH=`readlink -f $fasta`
    cp \$INDEX.amb \$FASTA_PATH.amb
    cp \$INDEX.ann \$FASTA_PATH.ann
    cp \$INDEX.bwt \$FASTA_PATH.bwt
    cp \$INDEX.pac \$FASTA_PATH.pac
    cp \$INDEX.sa \$FASTA_PATH.sa

    echo "pbrun fq2bam --ref $fasta $in_fq_command --read-group-sm $sample --out-bam ${prefix}.bam --num-gpus $task.accelerator.request ${interval_file_option} ${known_sites_option} ${out_qc_metrics_option} $args"

    pbrun \\
        fq2bam \\
        --ref $fasta \\
        $in_fq_command \\
        --read-group-sm $sample \\
        --out-bam ${prefix}.bam \\
        --num-gpus $task.accelerator.request \\
        ${interval_file_option} \\
        ${known_sites_option} \\
        ${out_qc_metrics_option} \\
        $args
    """
}