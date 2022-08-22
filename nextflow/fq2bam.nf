
params.inputFASTQ_1 = null
params.inputFASTQ_2 = null
params.inputRefTarball = null
params.inputKnownSites = null
params.inputKnownSitesTBI = null

params.sampleName = null
params.readGroupName = null
params.platformName = null

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

process fq2bam {
    tag "${sample_name}"
    label 'localGPU'
    label 'cloud4xT4'

    input:
    path inputFASTQ_1 from params.inputFASTQ_1
    path inputFASTQ_2 from params.inputFASTQ_2
    path inputRefTarball from params.inputRefTarball
    path inputKnownSites from params.inputKnownSites
    path inputKnownSitesTBI from params.inputKnownSitesTBI
    val pbPATH from params.pbPATH
    val tmpDir from params.tmpDir
    path pbLicense from params.pbLicense

    output:
    path "${inputFASTQ_1.baseName}.pb.bam"
    path "${inputFASTQ_1.baseName}.pb.bam.bai"
    path "${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt"

    script:
    """
    mkdir -p ${tmpDir} && \
    tar xf ${inputRefTarball} && \
    time ${pbPATH} fq2bam \
    --tmp-dir ${tmpDir} \
    --in-fq ${inputFASTQ_1} ${inputFASTQ_2} \
    --ref ${inputRefTarball.baseName} \
    --knownSites ${inputKnownSites} \
    --out-bam ${inputFASTQ_1.baseName}.pb.bam \
    --out-recal-file ${inputFASTQ_1.baseName}.pb.BQSR-REPORT.txt \
    --license-file ${pbLicense} 
    """
}
