#!/bin/bash

# system settings
PYTHON=`which python`

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=${PROJECT_BIN}/..

# external storage settings
EXTERNAL_BASE=${PROJECT_HOME}
DATA_DIR=${EXTERNAL_BASE}/data
LOG_DIR=${EXTERNAL_BASE}/log
MODEL_DIR=${EXTERNAL_BASE}/models
NOTEBOOK_DIR=${EXTERNAL_BASE}/notebooks

# notebook settings
NOTEBOOK_PORT=18888
NOTEBOOK_PASSWORD=123456

# serving settings
SERVING_PORT=18080
