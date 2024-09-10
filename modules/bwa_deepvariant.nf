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
    ${recalStub}
    """
}

process deepvariant {

    input:
    path inputBAM 
    path inputBAI
    path inputRef 

    output:
    path "${inputBAM.baseName}.deepvariant.vcf"

    script:
    """
    pbrun deepvariant \
    --in-bam ${inputBAM} \
    --ref ${inputRef} \
    --out-variants ${inputBAM.baseName}.deepvariant.vcf
    """
}

workflow Parabricks_BWA_DeepVariant {
    fq2bam(
        inputFASTQ_1=params.inputFASTQ_1,
        inputFASTQ_2=params.inputFASTQ_2,
        inputRef=params.inputRef, 
        inputKnownSitesVCF=params.inputKnownSitesVCF
    )
    deepvariant(
        inputBAM="${inputFASTQ_1.baseName}.pb.bam",
        inputBAI="${inputFASTQ_1.baseName}.pb.bam.bai",
        inputRef=params.inputRef
    )
}

workflow {
    Parabricks_BWA_DeepVariant()
}