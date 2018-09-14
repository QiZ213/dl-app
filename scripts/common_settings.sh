#!/bin/bash

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=$(cd $(dirname ${PROJECT_BIN}); pwd)
. ${PROJECT_BIN}/common_utils.sh

# python settings
PYTHON=python
export PYTHONPATH=${PROJECT_HOME}:${PYTHONPATH}

# application settings
PYTHON_VERSION=2
OS_VERSION=ubuntu14.04
CUDA_VERSION=8.0
CUDNN_VERSION=6
DEEP_LEARNING_FRAMEWORK=tensorflow
DEEP_LEARNING_VERSION=1.4.0

# deployment settings
# specify data dir to store raw data or persisted intermediate variables
DATA_DIR=

# specify log dir to store log
LOG_DIR=

# specify model dir to store models
MODEL_DIR=

# specify notebook dir to store .ipynb application,
NOTEBOOK_DIR=

# notebook settings
# specify port for jupyter notebook service, by default, it's "18888"
NOTEBOOK_PORT=18888

# specify password for jupyter notebook service, by default, it's "123456"
NOTEBOOK_PASSWORD=123456

# application settings
# define port for application service, by default, it's "18080"
SERVING_PORT=18080

# application settings
# define log level to write on the file. if ignore, by default, it's "logging.ERROR"
# please choose one of "debug | info | warning | error | critical | fatal". support UPPER and lower case
LOGGING_LEVEL=


case "${LOGGING_LEVEL}" in
  "") : ;;
  DEBUG|debug) : ;;
  INFO|info) : ;;
  WARN|warn) : ;;
  WARNING|warning) : ;;
  ERROR|error) : ;;
  CRITICAL|critical) : ;;
  FATAL|fatal) : ;;
  *) die "Invalid setting LOGGING_LEVEL, got \"${LOGGING_LEVEL}\"" ;;
esac

export LOGGING_LEVEL=${LOGGING_LEVEL}
