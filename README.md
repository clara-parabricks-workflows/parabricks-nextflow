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
    --GPU ON \
    -params-file example_inputs/test.fq2bam.json \
    -with-docker us-docker.pkg.dev/clara-lifesci/nv-parabricks-test/parabricks-cloud:3.7_ampere \
    testfq2b.nf
```

Note the following:
- The config/local.nf.conf configuration file defines the GPU label and should be passed for local runs.
- `--GPU ON` must be passed for GPU workflows to ensure that NextFlow calls Docker with GPU support enabled.
- The `-with-docker` command is required and should point to a valid Parabricks cloud-compatible Docker container. It must have no Entrypoint (i.e., `ENTRYPOINT bash`) and one should note the path to Parabricks within the container.
- The `-params-file` argument allows using a JSON stub for program arguments (rather than the command line). We recommend this way of invoking nextflow as it is easier to debug and more amenable to batch processing.

### Experimenting with GCP support
An example config file for Google Cloud Project's Life Sciences Pipelines API (PAPI) is available in `config/gcp.nf.conf`. To run on GCP, you must have a valid project with the Pipelines API enabled and have local application credentials for a service account. You will need to export your GCP project name and credential path into your environment before running, as well as define machine types and corresponding labels on each NextFlow task in your workflow.
