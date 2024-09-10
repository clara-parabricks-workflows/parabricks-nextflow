# Parabricks NextFlow Workflows 

This repo contains example code for running NVIDIA Parabricks using NextFlow. The examples here are minimal and are meant as a starting point to show users how to connect Parabricks and NextFlow. 

The two example workflows are: 

1. Alignment using FQ2BAM
2. Germline Variant Calling using Haplotype and DeepVariant

# Getting Started

For hardware requirements, see the [Parabricks documentation](https://docs.nvidia.com/clara/parabricks/latest/gettingstarted.html#hardware-requirementss). 

The software requirements are: 

- Docker
- nvidia-docker
- [NextFlow](https://www.nextflow.io/docs/latest/install.html#install-nextflow)

An example dataset with all the necessary files to run these examples can be found at 

# Running Alignment using FQ2BAM 

The [Parabricks fq2bam tool](https://docs.nvidia.com/clara/parabricks/latest/documentation/tooldocs/man_fq2bam.html#man-fq2bam) is an accelerated BWA mem implementation. The tool also includes BAM sorting, duplicate marking, and optionally Base Quality Score Recalibration (BQSR). 

The `fq2bam.nf` script in this repository demonstrates how to run this tool with a set of input reads, producing a BAM file, its BAI index and a BQSR report for use with HaplotypeCaller.

Below is an example command line for running the `fq2bam.nf` script:

```bash
nextflow run \
    -c config/local.nf.conf \
    -params-file example_inputs/test.fq2bam.json \
    nexflow/fq2bam.nf
```

| Input File | Purpose |
| -------- | ------- |
| `local.nf.conf` | Where the Docker container is defined. See the [NGC Registry](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks) for the latest version. They do not require an account to view or download. |
| `test.fq2bam.json` | Where the input data paths are defined. Check that the paths are correct before running, as the exact path will be different for everyone. Use absolute paths only. |
| `fq2bam.nf` | The NextFlow file with the workflow definition. |

# Running Germline Variant Calling

[Parabricks HaplotypeCaller](https://docs.nvidia.com/clara/parabricks/latest/documentation/tooldocs/man_haplotypecaller.html#man-haplotypecaller) and [Parabricks DeepVaraiant](https://docs.nvidia.com/clara/parabricks/latest/documentation/tooldocs/man_deepvariant.html#man-deepvariant) are GPU accelerated versions of germline variant callers. 

The `germline.nf` script in this repository demonstrates how to run these tools back to back with a set of input bams, producing a VCF file each. 

Below is an example command line for running the `germline.nf` script:

```bash
~/nextflow run \
    -c config/local.nf.conf \
    -params-file example_inputs/test.germline.json \
    nextflow/germline.nf
```

| Input File | Purpose |
| -------- | ------- |
| `local.nf.conf` | Where the Docker container is defined. See the [NGC Registry](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks) for the latest version. They do not require an account to view or download. |
| `test.germline.json` | Where the input data paths are defined. Check that the paths are correct before running, as the exact path will be different for everyone. Use absolute paths only. |
| `germline.nf` | The NextFlow file with the workflow definition. |

# (Deprecated) Experimenting with GCP support
An example config file for Google Cloud Project's Life Sciences Pipelines API (PAPI) is available in `config/gcp.nf.conf`. To run on GCP, you must have a valid project with the Pipelines API enabled and have local application credentials for a service account. You will need to export your GCP project name and credential path into your environment before running, as well as define machine types and corresponding labels on each NextFlow task in your workflow.


## Cloud GPU Availability

Not all Cloud Service Providers support every NVIDIA GPU. Below we detail some basic expectations for GPU availability per cloud provider;
for details on other CSPs, please file an issue with an example configuration file if possible.

The following nextflow config guidelines apply for maximizing cost/performance on broadest available cloud GPUs (as of Parabricks 4.0).
**Note: these recomemendations are subject to change and we encourage individual benchmarking for your workloads**. The following numbers
were derived using 30X whole-genome sequencing (WGS) data and optimized for cost-to-performance ratio:

fq2bam and alignment tasks:
```
      cpu = 32
      memory = 196
      accelerator = [request: 4, type:'nvidia-tesla-t4']
      disk = "1000 GB"
```

For HaplotypeCaller and DeepVariant:
```
      cpu = 
      memory = 196
      accelerator = [request: 4, type:'nvidia-tesla-t4']
      disk = "1000 GB"
```

**Note: on AWS, A10 provides further improved cost / performance**

V100, and A100 GPUs offer an improvement in performance for time- or throughput-critical workloads.

Many GPUs are available using spot or preemptible instances. As Parabricks is optimized for speed, the
chance of a job completing before preemption is relatively high. We strongly recommend runnning on preemptible
instances if cost is a consideration.



**Google Cloud Life Sciences Pipelines API (PAPI)**
- Nvidia T4 : broadly available, best cost:performance. Add this stub to your nextflow config:
        `accelerator = [request: 4, type:'nvidia-tesla-t4']`
- Nvidia V100 : broadly available, best performance. Add this stub to your nextflow config:
        `accelerator = [request: 4, type:'nvidia-tesla-v100']`


**Microsft Azure Batch**
Azure batch does not yet support the `accelerators` directive. GPUs must be acquired by specifying a 
GPU-powered vmType in the pool configuration, like so:


```
azure {
    batch {
        pools {
            auto {
               autoScale = true
               vmType = '<GPU powered VM type>'
               vmCount = 1
               maxVmCount = 5
            }
        }
    }
}
```


Please specify one of the following GPU-powered VM types for GPU
tasks. 
- Nvidia V100: use `vmType = 'Standard_NC24s_v3'`
- Nvidia T4: use `vmType = 'Standard_NC64as_T4_v3'`
- Nvidia A100: use either `vmType = 'Standard_NC48ads_A100_v4'` (2x A100 GPUs) or `vmType = 'Standard_NC96ads_A100_v4'` (4x A100 GPUs)

**Amazon Web Services (AWS) Batch**
Complete details available [in the AWS Batch User Guide](https://docs.aws.amazon.com/batch/latest/userguide/gpu-jobs.html)
- Nvidia T4: add the following stub to your nextflow label: `accelerator = [request: 4, type:'nvidia-tesla-t4']` OR use instance type `g4dn.12xlarge`
- Nvidia V100: add the following stub to your nextflow label: `accelerator = [request: 4, type:'nvidia-tesla-v100']` OR use instance type `p3.8xlarge` or `p3.16xlarge`
- Nvidia A10: add the following stub to your nextflow label: `accelerator = [request: 4, type:'nvidia-tesla-a10']` OR use instance type `g5.12xlarge`


