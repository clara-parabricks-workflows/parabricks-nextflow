#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process haplotypecaller {

    input:
    path inputBAM 
    path inputBAI 
    path inputBQSR 
    path inputRef

    output:
    path "${inputBAM.baseName}.haplotypecaller.vcf"

    script:
    def bqsrStub = inputBQSR ? "--in-recal-file ${inputBQSR}" : ""

    """
    pbrun haplotypecaller \
    --ref ${inputRef} \
    --in-bam ${inputBAM} \
    --out-variants "${inputBAM.baseName}.haplotypecaller.vcf" \
    ${bqsrStub}
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

workflow Parabricks_Germline {
    haplotypecaller(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputBQSR=params.inputBQSR,
        inputRef=params.inputRef
    )
    deepvariant(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputRef=params.inputRef
    )
}

workflow {
    Parabricks_Germline()
}