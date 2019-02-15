#!/bin/bash
# script to deploy project
curr_dir=$(dirname ${BASH_SOURCE[0]})
. "${curr_dir}/../common_settings.sh"

if [[ $# -lt 8 ]]; then
  red_echo "Illegal arguments: "
  red_echo "  ./deploy.sh target_home task_name task_type module_name docker_tag device_type registry_idc image_existed dry_run [cmd]"
  echo "e.g. NV_GPU=1,2 bash deploy.sh ~/opt/quick-start examples service examples examples:0.1 gpu aws yes yes [cmd] "
  exit 128
fi

TARGET_HOME=$1 # e.g. "~/opt/quick-start"
shift 1
TASK_NAME=$1 # e.g. "examples"
shift 1
TASK_TYPE=$1 # e.g. "service"
shift 1
MODULE_NAME=$1 # e.g. "examples"
shift 1
DOCKER_TAG=$1 # e.g. "examples:0.1"
shift 1
DEVICE_TYPE=$1  # e.g. "gpu" or "cpu"
shift 1
REGISTRY_IDC=$1 # e.g. "aws" or "ppd"
shift 1
IMAGE_EXISTED=$1 # e.g. "yes" or "no"
shift 1
DRY_RUN=$1 # e.g. "yes" or "no"
shift 1
CMD="$@"

: ${BUILD_ONLY:=no}

TASK_TYPE_SETTINGS=${PROJECT_BIN}/tools/task_types/${TASK_TYPE}.sh
TARGET_COMMON_SETTINGS=${TARGET_HOME}/scripts/common_settings.sh

. ${TARGET_COMMON_SETTINGS}
. ${curr_dir}/docker_helpers.sh

# link external dir to user project
link_dir() {
  local src=$1
  local tgt=$2

  blue_echo "link ${src} to ${tgt}"
  [[ -e ${src} ]] || mkdir -p ${src}
  [[ -L ${tgt} ]] && rm ${tgt}
  [[ -e ${tgt} ]] && rm -r ${tgt}
  ln -s ${src} ${tgt};
  die_if_err "fail to link ${src} to ${tgt}";
}

copy_externals() {
  [[ -d "${RESOURCE_DIR}" ]] && copy_missing ${RESOURCE_DIR} ${TARGET_HOME}/resources
}

link_externals() {
  default_base_dir=$(get_default_base_dir)
  : ${DATA_DIR:=${default_base_dir}/dl-data/${TASK_NAME}}
  : ${LOG_DIR:=${default_base_dir}/dl-log/${TASK_NAME}}
  : ${MODEL_DIR:=${default_base_dir}/dl-models/${TASK_NAME}}
  : ${NOTEBOOK_DIR:=${default_base_dir}/dl-notebooks/${TASK_NAME}}

  link_dir ${DATA_DIR} ${TARGET_HOME}/data
  link_dir ${LOG_DIR} ${TARGET_HOME}/log
  link_dir ${MODEL_DIR} ${TARGET_HOME}/models
  link_dir ${NOTEBOOK_DIR} ${TARGET_HOME}/notebooks
}

prepare
copy_externals
if not_yes ${IMAGE_EXISTED}; then
  build
fi
if not_yes ${BUILD_ONLY}; then
  link_externals
  run
fi
