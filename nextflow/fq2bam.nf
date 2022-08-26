#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
 * Clara Parabricks NextFlow
 * fq2bam.nf
*/


/**
* Inputs
*/
params.inputFASTQ_1 = null
params.inputFASTQ_2 = null
params.inputRefTarball = null
params.inputKnownSitesVCF = null
params.inputKnownSitesTBI = null

params.inputSampleName = null
params.readGroupName = null
params.platformName = null

params.pbPATH = ""
params.pbLicense = ""

// Dynamic Process configuration not yet implemented.
// params.pbDocker = "parabricks-cloud:latest"
// params.tmpDir = "tmp_fq2bam"
// params.gpuModel = "nvidia-tesla-v100"
// params.nGPU = 4
// params.nThreads = 32
// params.gbRAM = 120
// params.diskGB = 120
// params.runtimeMinutes = 600
// params.maxPreemptAttempts = 3

process fq2bam {
    label 'localGPU'
    label 'cloud4xT4'

    input:
    path inputFASTQ_1
    path inputFASTQ_2
    path inputRefTarball
    path inputKnownSitesVCF
    path inputKnownSitesTBI
    val inputSampleName
    val pbPATH
    val tmpDir
    path pbLicense

    output:
    path "${inputFASTQ_1.baseName}.pb.bam"
    path "${inputFASTQ_1.baseName}.pb.bam.bai"
    path "${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt"

    script:
    def knownSitesStub = inputKnownSitesVCF ? "--knownSites ${inputKnownSitesVCF}" : ''
    def recalStub = inputKnownSitesVCF ? "--out-recal-file ${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt" : ''
    // def sampleNameStub = inputSampleName ? "--read-group-sm ${inputSampleName}" : ""
    // def licenseStub = pbLicense ? "--license-file ${pbLicense}" : ""
    """
    mkdir -p ${tmpDir} && \
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} fq2bam \
    --tmp-dir ${tmpDir} \
    --in-fq ${inputFASTQ_1} ${inputFASTQ_2} \
    --ref ${inputRefTarball.baseName} \
    --out-bam ${inputFASTQ_1.baseName}.pb.bam \
    ${knownSitesStub} \
    ${recalStub}
    """

}


workflow ClaraParabricks_fq2bam {

/*
    path inputFASTQ_1
    path inputFASTQ_2
    path inputRefTarball
    path inputKnownSitesVCF
    path inputKnownSitesTBI
    val inputSampleName
    val pbPATH
    val tmpDir
    path pbLicense
*/

    fq2bam( inputFASTQ_1=params.inputFASTQ_1,
            inputFASTQ_2=params.inputFASTQ_2,
            inputRefTarball=params.inputRefTarball,
            inputKnownSitesVCF=params.inputKnownSitesVCF,
            inputKnownSitesTBI=params.inputKnownSitesTBI,
            inputSampleName=params.inputSampleName,
            pbPATH=params.pbPATH,
            tmpDir=params.tmpDir,
            pbLicense=params.pbLicense)
}

workflow {
    ClaraParabricks_fq2bam()
}
