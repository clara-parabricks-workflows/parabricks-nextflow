#!/bin/bash

CONFIG="/home/ubuntu/parabricks-nextflow/config/local.nf.conf"
PARAMS="/home/ubuntu/parabricks-nextflow/example_inputs/test.fq2bam.json"
NF_SCRIPT="/home/ubuntu/parabricks-nextflow/nextflow/fq2bam.nf"

nextflow run \
    -c ${CONFIG} \
    -params-file ${PARAMS} \
    ${NF_SCRIPT}