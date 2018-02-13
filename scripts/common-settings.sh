#!/bin/bash

# system settings
# executable python bin file, it will decide python version in docker
# by default, it'll use system python, you can modify it for your need
PYTHON=`which python`

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=${PROJECT_BIN}/..

## external storage settings
# base dir for external folder, which can be reached outside docker
# by default, it's current project home, you can modify it to your own folder
EXTERNAL_BASE=${PROJECT_HOME}

# data dir to store raw data or presisted intermediate variables
# by default, it's "./data", you can modify it to your own folder
export DATA_DIR=${EXTERNAL_BASE}/data

# log dir to store logs, which can be used to analyze in future
# by default, it's "./log", modify it to your own folder
export LOG_DIR=${EXTERNAL_BASE}/log

# model dir to store models
# by default, it's "./models", modify it to your own folder
export MODEL_DIR=${EXTERNAL_BASE}/models

# notebook dir to store .ipynb codes and their dependencies
# by default, it's "./notebooks", modify it to your own folder
export NOTEBOOK_DIR=${EXTERNAL_BASE}/notebooks

## notebook settings
# port for jupyter notebook service
# by default, it's "18888", modify it to avoid conflicts
NOTEBOOK_PORT=18888

# password for jupyter notebook service
# by default, it's "123456", modify it for your need
NOTEBOOK_PASSWORD=123456

## serving settings
# port for service
# by default, it's "18080", modify it to avoid conflicts
SERVING_PORT=18080

