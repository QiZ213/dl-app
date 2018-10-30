#!/bin/bash
# script to deploy project
if [[ $# -lt 8 ]]; then
  red_echo "Illegal arguments: ./deploy.sh task_home image_existed task_name task_version docker_tag task_type device_type registry_idc dry_run [cmd]"
  echo "e.g. $ /bin/bash deploy.sh ~/ocr yes poem 0.1 poem:0.1 service|train|notebook|debug cpu|gpu ppd no [cmd]"
  exit 128
fi
curr_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. ${curr_dir}/../common_settings.sh

TASK_HOME="$1"
IMAGE_EXISTED="$2"
shift 2

. ${TASK_HOME}/scripts/common_settings.sh
. ${curr_dir}/docker_helpers.sh $@

# link external dir to user project
link_dir() {
  blue_echo "link $1 to $2"
  [[ -d $1 ]] || mkdir -p $1
  [[ -L $2 ]] && rm $2
  [[ -e $2 ]] && rm -r $2
  ln -s $1 $2;
  die_if_err "fail to link $1 to $2";
}

link_externals() {
  local base_dir=/opt
  [[ -w ${base_dir} ]] || base_dir=~/opt
  link_dir ${DATA_DIR:=${base_dir}/dl-data/${TASK_NAME}} ${TASK_HOME}/data
  link_dir ${LOG_DIR:=${base_dir}/dl-log/${TASK_NAME}} ${TASK_HOME}/log
  link_dir ${MODEL_DIR:=${base_dir}/dl-models/${TASK_NAME}} ${TASK_HOME}/models
  link_dir ${NOTEBOOK_DIR:=${base_dir}/dl-notebooks/${TASK_NAME}} ${TASK_HOME}/notebooks
}

# start docker task
prepare
link_externals
if not_yes ${IMAGE_EXISTED}; then
  build
fi
run
