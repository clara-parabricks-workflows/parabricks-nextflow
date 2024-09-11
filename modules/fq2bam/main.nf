process PARABRICKS_FQ2BAM {
    tag "$meta.id"
    label 'process_high'
    accelerator 1

    input:
    tuple val(meta), path(reads)
    path index 
    tuple path(fasta), path(fai), path(genome_file), path(chrom_sizes), path(genome_dict)
    path inputKnownSitesVCF

    output:
    tuple val(meta), path("*.bam"), path("*.bai"), emit: bam_bai
    tuple val(meta), path("*.log"), emit: log

    script:
    def args = task.ext.args ?: ''
    def prefix = meta.prefix ? "${meta.prefix}" : "${meta.id}"
    def read_group = meta.read_group ? "${meta.read_group}" : "RG"
    def platform = meta.platform ? "${meta.platform}" : "PL"
    def platform_unit = meta.read_group ? "${meta.read_group}" : "RG"
    def sample = meta.sample ? "${meta.sample}" : "SM"
    def read_group_string = "@RG\\tID:$read_group\\tLB:$sample\\tPL:$platform\\tSM:$sample\\tPU:$platform_unit"

    def in_fq_command = meta.single_end ? "--in-se-fq $reads \"$read_group_string\"" : "--in-fq $reads \"$read_group_string\""

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

    echo "pbrun fq2bam --ref $fasta $in_fq_command --read-group-sm $sample --out-bam ${prefix}.bam --num-gpus $task.accelerator.request $args"

    pbrun \\
        fq2bam \\
        --ref $fasta \\
        $in_fq_command \\
        --read-group-sm $sample \\
        --out-bam ${prefix}.bam \\
        --num-gpus $task.accelerator.request \\
        $args
    """
}