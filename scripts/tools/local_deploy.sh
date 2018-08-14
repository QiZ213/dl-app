#!/bin/bash
# Scripts to deploy project at local.
if [[ $# -ne 2 ]]; then
  echo "Illegal arguments: ./local_deploy.sh project_name task_type"
  echo "e.g. $ /bin/bash ./local_deploy.sh service_name task_type"
  exit 128
fi
. "${BASH_SOURCE%/*}/../common_settings.sh"


PROJECT_NAME=$1
TASK_TYPE=$2

check_port_listen() {
  port=$1
  if [ -n ${port} ]; then
    port_pattern=":${port} "
  fi
  netstat -ln | grep ${port_pattern}
}

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
      mkdir -p ${SOURCE_DIR} \
        || echo "fail to create ${SOURCE_DIR}, please make it manually"
    fi
  fi
  if [[ "${SOURCE_DIR}" != "${TARGET_DIR}" ]]; then
    test -d ${TARGET_DIR} \
      || ln -s ${SOURCE_DIR} ${TARGET_DIR}
  fi
}

case ${TASK_TYPE} in
  notebook)
    check_port_listen ${NOTEBOOK_PORT} && {
      red_echo "Error: remote port for notebook: ${NOTEBOOK_PORT} is listened" \
      && red_echo "  Please check it and replace another one in scripts/common_setting.sh" \
      && exit 128
    } ;;
  service)
    check_port_listen ${SERVING_PORT} && {
      red_echo "Error: remote port for service: ${SERVING_PORT} is listened" \
      && red_echo "  Please check it and replace another one in scripts/common_setting.sh" \
      && exit 128
    } ;;
  *)
    :
    ;;
esac

link_dir_for_docker data ${DATA_DIR}
link_dir_for_docker log ${LOG_DIR}
link_dir_for_docker models ${MODEL_DIR}
link_dir_for_docker notebooks ${NOTEBOOK_DIR}
