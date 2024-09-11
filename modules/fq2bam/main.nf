process PARABRICKS_FQ2BAM {

    input:
    path inputFASTQ_1
    path inputFASTQ_2
    path index 
    tuple path(fasta), path(fai), path(genome_file), path(chrom_sizes), path(genome_dict)
    path inputKnownSitesVCF

    output:
    path "${inputFASTQ_1.baseName}.pb.bam"
    path "${inputFASTQ_1.baseName}.pb.bam.bai"
    path "${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt"

    script:
    def knownSitesStub = inputKnownSitesVCF ? "--knownSites ${inputKnownSitesVCF}" : ''
    def recalStub = inputKnownSitesVCF ? "--out-recal-file ${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt" : ''

    """
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

    pbrun fq2bam \
    --in-fq ${inputFASTQ_1} ${inputFASTQ_2} \
    --ref $fasta \
    --out-bam ${inputFASTQ_1.baseName}.pb.bam \
    ${knownSitesStub} \
    ${recalStub} --low-memory
    """
}