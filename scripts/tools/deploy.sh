#!/bin/bash
# Scripts to deploy project.
if [[ $# -ne 1 ]]; then
  echo "Illegal arguments: ./deploy.sh project_name"
  echo "e.g. $ /bin/bash ./deploy.sh service_name"
  exit 128
fi
. "${BASH_SOURCE%/*}/../common_settings.sh"

PROJECT_NAME=$1

link_dir_for_docker(){
  if [[ $# -gt 2 ]]; then
    echo "usage: link_dir_for_docker target_tag [source]"
    exit 64
  fi
  TARGET_TAG=$1
  TARGET_DIR=${PROJECT_HOME}/${TARGET_TAG}
  if [[ $# -eq 1 ]]; then
    SOURCE_DIR=/opt/${TARGET_TAG}/${PROJECT_NAME}
    if [[ ! -d ${SOURCE_DIR} ]]; then
      sudo mkdir -p ${SOURCE_DIR} \
        && sudo chown $(whoami) ${SOURCE_DIR}
    fi
  else
    SOURCE_DIR=$2
    if [[ ! -d ${SOURCE_DIR} ]]; then
      echo "WARNING: ${SOURCE_DIR} not existed"
      sudo mkdir -p ${SOURCE_DIR} \
        && sudo chown $(whoami) ${SOURCE_DIR}
    fi
  fi
  if [[ "${SOURCE_DIR}" != "${TARGET_DIR}" ]]; then
    ln -s ${SOURCE_DIR} ${TARGET_DIR}
  fi
}

link_dir_for_docker data ${DATA_DIR}
link_dir_for_docker log ${LOG_DIR}
link_dir_for_docker models ${MODEL_DIR}
link_dir_for_docker notebooks ${NOTEBOOK_DIR}
