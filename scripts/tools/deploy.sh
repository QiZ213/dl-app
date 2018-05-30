#!/bin/bash
# Scripts to deploy project.
if [ $# -ne 1 ]; then
  echo "Illegal arguments: ./run-service.sh project_name"
  echo "e.g. $ /bin/bash ./deploy.sh ocr_service"
  exit 128
fi

PROJECT_NAME=$1

curr_dir=$(dirname $0)
. ${curr_dir}/../common-settings.sh

link_dir_for_docker(){
  if [ $# -gt 2 ]; then
    echo "usage: link_dir_for_docker target_tag [source]"
    exit 64
  fi
  TARGET_TAG=$1
  TARGET_DIR=${PROJECT_NAME}/${TARGET_TAG}
  if [ $# -eq 1 ]; then
    SOURCE_DIR=/opt/${TARGET_TAG}/${PROJECT_NAME}
    if [ ! -d ${SOURCE_DIR} ]; then
      sudo mkdir -p ${SOURCE_DIR}
      sudo chown $(whoami) ${SOURCE_DIR}
    fi
  else
    SOURCE_DIR=$2
    if [ ! -d ${SOURCE_DIR} ]; then
      echo "${SOURCE_DIR} not existed"
      exit 64
    fi
  fi
  ln -s ${SOURCE_DIR} ${TARGET_DIR}
}

link_dir_for_docker data ${DATA_DIR}
link_dir_for_docker log ${LOG_DIR}
link_dir_for_docker models ${MODEL_DIR}
link_dir_for_docker notebooks ${NOTEBOOK_DIR}
