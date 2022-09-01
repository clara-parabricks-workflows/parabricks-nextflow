Parabricks-NextFlow
-------------------
August 2022

# Overview
This repo contains experimental code for running Nvidia Clara Parabricks in NextFlow.


# Getting Started
After cloning this repository, you'll need a valid parabricks installation (including a license) as 
well as a Parabricks cloud-compatible docker container to run. In addition, you should have at least one
Parabricks compatible GPU, 12 CPU cores, and 64 GB of RAM to expect to be able to test. Two GPUs are required
for running Parabricks in production.


## Set up and environment
Parabricks-nextflow requires the following dependencies:
- Docker
- nvidia-docker
- NextFlow

After installing these tools, you will need a cloud-compatible Parabricks container and a Parabricks license.
Please contact Nvidia for help acquiring these.

## Running fq2bam locally

The Parabricks fq2bam tool is an accelerated BWA mem implementation. The tool also includes BAM sorting, duplicate marking, and optionally Base Quality Score Recalibration (BQSR). The `fq2bam.nf` script in this repository demonstrates how to run this tool with a set of input reads, producing a BAM file, its BAI index and a BQSR report for use with HaplotypeCaller.

Below is an example command line for running the fq2bam.nf script:

```bash
~/nextflow run \
    -c config/local.nf.conf \
    -params-file example_inputs/test.fq2bam.json \
    -with-docker 'gcr.io/clara-lifesci/parabricks-cloud:4.0.0-1.beta2' \
    testfq2b.nf
```

Note the following:
- The config/local.nf.conf configuration file defines the GPU-enabled local label and should be passed for local runs.
- The `-with-docker` command is required and should point to a valid Parabricks cloud-compatible Docker container. It must have no Entrypoint (i.e., `ENTRYPOINT bash`) and one should note the path to Parabricks within the container.
- The `-params-file` argument allows using a JSON stub for program arguments (rather than the command line). We recommend this way of invoking nextflow as it is easier to debug and more amenable to batch processing.

### Experimenting with GCP support
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


