#!/bin/bash

# system settings
# executable python bin file, it will decide python version in docker
# by default, it'll use system python, you can modify it for your need
PYTHON=`which python`

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=${PROJECT_BIN}/..
PROJECT_NAME="ocr-service"

# data dir to store raw data or presisted intermediate variables
# by default, it's "./data", you can modify it to your own folder
DATA_DIR=

# log dir to store logs, which can be used to analyze in future
# by default, it's "./log", modify it to your own folder
LOG_DIR=

# model dir to store models
# by default, it's "./models", modify it to your own folder
MODEL_DIR=

# notebook dir to store .ipynb codes and their dependencies
# by default, it's "./notebooks", modify it to your own folder
NOTEBOOK_DIR=

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


# deploy external storage, including data, log, models and notebooks
link_dir_for_docker(){
  TARGET=$1
  SOURCE_DIR=$2
  DEFAULT_SOURCE_DIR=/opt/${TARGET}/${PROJECT_NAME}
  TARGET_DIR=${PROJECT_HOME}/${TARGET}

  if [ ! -d ${TARGET_DIR} ]; then
    if [ -z "${SOURCE_DIR}" ]; then
      test -d ${DEFAULT_SOURCE_DIR} \
          || sudo mkdir -p ${DEFAULT_SOURCE_DIR} \
          && sudo chown $(whoami) ${DEFAULT_SOURCE_DIR}
      ln -s ${DEFAULT_SOURCE_DIR} ${TARGET_DIR}
    else
      if [ ! -d ${SOURCE_DIR} ]; then
        echo "${SOURCE_DIR} not existed"
        exit 64
      fi
      ln -s ${SOURCE_DIR} ${TARGET_DIR}
    fi
  fi
}

link_dir_for_docker data ${DATA_DIR}
link_dir_for_docker log ${LOG_DIR}
link_dir_for_docker models ${MODEL_DIR}
link_dir_for_docker notebooks ${NOTEBOOK_DIR}