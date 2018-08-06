#!/bin/bash

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=${PROJECT_BIN}/..

# system
export PYTHONPATH=${PROJECT_HOME}:${PYTHONPATH}

# env settings
PYTHON=python
PYTHON_VERSION=2
OS_VERSION=ubuntu14.04
CUDA_VERSION=8.0
CUDNN_VERSION=6
DEEP_LEARNING_FRAMEWORK=tensorflow
DEEP_LEARNING_VERSION=1.4.0

# deployment settings
# specify data dir to store raw data or persisted intermediate variables
DATA_DIR=${PROJECT_HOME}/data

# specify log dir to store log
LOG_DIR=${PROJECT_HOME}/log

# specify model dir to store models
MODEL_DIR=${PROJECT_HOME}/models

# specify notebook dir to store .ipynb application,
NOTEBOOK_DIR=${PROJECT_HOME}/notebooks

# notebook settings
# specify port for jupyter notebook service, by default, it's "18888"
NOTEBOOK_PORT=18888

# specify password for jupyter notebook service, by default, it's "123456"
NOTEBOOK_PASSWORD=123456

# application settings
# define port for application service, by default, it's "18080"
SERVING_PORT=18081
