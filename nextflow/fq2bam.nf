#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process fq2bam {

    input:
    path inputFASTQ_1
    path inputFASTQ_2
    path inputRef
    path inputKnownSitesVCF

    output:
    path "${inputFASTQ_1.baseName}.pb.bam"
    path "${inputFASTQ_1.baseName}.pb.bam.bai"
    path "${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt"

    script:
    def knownSitesStub = inputKnownSitesVCF ? "--knownSites ${inputKnownSitesVCF}" : ''
    def recalStub = inputKnownSitesVCF ? "--out-recal-file ${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt" : ''

    """
    pbrun fq2bam \
    --in-fq ${inputFASTQ_1} ${inputFASTQ_2} \
    --ref ${inputRef} \
    --out-bam ${inputFASTQ_1.baseName}.pb.bam \
    ${knownSitesStub} \
    ${recalStub} --low-memory
    """
}

workflow Parabricks_fq2bam {
    fq2bam(
        inputFASTQ_1=params.inputFASTQ_1,
        inputFASTQ_2=params.inputFASTQ_2,
        inputRef=params.inputRef, 
        inputKnownSitesVCF=params.inputKnownSitesVCF
    )
}

workflow {
    Parabricks_fq2bam()
}
