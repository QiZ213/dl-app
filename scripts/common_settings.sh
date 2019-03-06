#!/bin/bash
# project settings
: ${PROJECT_BIN:=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)}
: ${PROJECT_HOME:=$(cd $(dirname ${PROJECT_BIN}); pwd)}
if [[ -e ${PROJECT_BIN}/common_utils.sh ]]; then
  . ${PROJECT_BIN}/common_utils.sh
fi

# python settings
PYTHON=python
export PYTHONPATH=${PROJECT_HOME}:${PYTHONPATH}

## Reference Documents:
## http://git.ppdaicorp.com/bird/dl-application/wikis/%E9%85%8D%E7%BD%AEcommon_settings.sh

# application settings
PYTHON_VERSION=
OS_VERSION=
## Setting the dependency of dl-framework, cuda, cudnn could refer to
CUDA_VERSION=
CUDNN_VERSION=
DEEP_LEARNING_FRAMEWORK=
DEEP_LEARNING_VERSION=

# deployment settings
# specify data dir to store raw data or persisted intermediate variables, for example,
# DATA_DIR=~/dl-data/$(basename ${PROJECT_HOME})
DATA_DIR=

# specify log dir to store log, for example,
# LOG_DIR=~/dl-log/$(basename ${PROJECT_HOME})
LOG_DIR=

# specify model dir to store models, for example,
# MODEL_DIR=~/dl-models/$(basename ${PROJECT_HOME})
MODEL_DIR=

# specify notebook dir to store .ipynb application, for example,
# NOTEBOOK_DIR=~/dl-notebooks/$(basename ${PROJECT_HOME})
NOTEBOOK_DIR=

# specify resources dir to store something need to copy to docker image,
RESOURCE_DIR=

# notebook settings
# specify port for jupyter notebook service, by default, it's "18888"
NOTEBOOK_PORT=18888

# specify password for jupyter notebook service, by default, it's "123456"
NOTEBOOK_PASSWORD=123456

# application settings
# define port for application service, by default, it's "18080"
SERVING_PORT=18080

