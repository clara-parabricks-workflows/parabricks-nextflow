#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
 * Clara Parabricks NextFlow
 * germline_calling.nf
*/


/**
* Inputs
*/
params.inputBAM = null
params.inputBAI = null
params.inputBQSR = null
params.inputRefTarball = null
params.gvcfMode = false

params.pbPATH = null
params.pbLicense = null

params.pbDocker = "parabricks-cloud:latest"
params.tmpDir = "tmp_fq2bam"
params.gpuModel = "nvidia-tesla-v100"
params.nGPU = 4
params.nThreads = 32
params.gbRAM = 120
params.diskGB = 120
params.runtimeMinutes = 600
params.maxPreemptAttempts = 3



process haplotypecaller {
    tag "${sample_name}-haplotypecaller"
    label 'localGPU'
    label 'cloud4xT4'

    input:
    path inputBAM 
    path inputBAI 
    path inputBQSR 
    path inputRefTarball 
    val gvcfMode
    val pbPATH 
    path pbLicense 

    output:
    path "${inputBAM.baseName}.haplotypecaller.vcf.gz"
    path "${inputBAM.baseName}.haplotypecaler.vc.gz.tbi"

    script:
    def bqsrStub = inputBQSR ? "--in-recal-file ${inputBQSR}" : ""
    def gvcfStub = gvcfMode ? "--gvcf" : ""
    def haplotypecalleroptionsStub = ""
    def licenseStub = pbLicense ? "--license-file ${pbLicense}" : ""
    """
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} haplotypecaller \
    --ref ${inputRefTarball.baseName} \
    --in-bam ${inputBAM} \
    --out-variants "${inputBAM.baseName}.haplotypecaller.vcf"
    ${gvcfStub} \
    ${bqsrStub} \
    ${haplotypecalleroptionsStub} \
    ${licenseStub} && \
    bgzip ${inputBAM.baseName}.haplotypecaller.vcf && \
    tabix ${inputBAM.baseName}.haplotypecaller.vcf.gz
    """
}


process deepvariant {
    tag "${sample_name}-deepvariant"
    label 'localGPU'
    label 'cloud4xT4'

    input:
    path inputBAM 
    path inputBAI
    path inputRefTarball 
    val gvcfMode 
    val pbPATH
    path pbLicense


    output:
    path "${inputBAM.baseName}.deepvariant.vcf.gz"
    path "${inputBAM.baseName}.deepvariant.vcf.gz.tbi"

    script:
    def gvcfStub = gvcfMode ? "--gvcf" : ""
    def licenseStub = pbLicense ? "--license-file ${pbLicense}" : ""
    """
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} deepvariant \
    --in-bam ${inputBAM} \
    --ref ${inputRefTarball.baseName} \
    --out-variants ${inputBAM.baseName}.deepvariant.vcf \
    ${gvcfStub} \
    ${licenseStub} && \
    bgzip ${inputBAM.baseName}.deepvariant.vcf && \
    tabix ${inputBAM.baseName}.deepvariant.vcf.gz
    """
}

workflow ClaraParabricks_Germline {
    haplotypecaller(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputBQSR=params.inputBQSR,
        inputRefTarball=params.inputRefTarball,
        gvcfMode=params.gvcfMode,
        pbPATH=params.pbPATH,
        pbLicense=params.pbLicense
    )
    deepvariant(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputRefTarball=params.inputRefTarball,
        gvcfMode=params.gvcfMode,
        pbPATH=params.pbPATH,
        pbLicense=params.pbLicense
    )
}

workflow {
    ClaraParabricks_Germline()
}