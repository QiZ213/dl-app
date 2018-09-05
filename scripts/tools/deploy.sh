#!/bin/bash
# script to assemble user project
if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./launch.sh idc_name device_type task_name version task_type [image_existed]"
  echo "e.g. $ /bin/bash launch.sh ppd|aws cpu|gpu ocr-train 0.1 service|train|notebook|debug [no]"
  exit 128
fi

CURR_DIR=$(dirname $0)
. "${CURR_DIR}/../common_settings.sh"

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

. ${USER_PROJECT_HOME}/scripts/common_settings.sh
. ${current_bin}/tools/docker_helpers.sh $@

# link external dir to user project
default_base_dir=/opt
[[ -w ${default_base_dir}/ ]] || default_base_dir=~/

: ${DATA_DIR:=${default_base_dir}/data/${PROJECT_NAME}}
: ${LOG_DIR:=${default_base_dir}/log/${PROJECT_NAME}}
: ${MODEL_DIR:=${default_base_dir}/models/${PROJECT_NAME}}
: ${NOTEBOOK_DIR:=${default_base_dir}/notebooks/${PROJECT_NAME}}

link_dir ${DATA_DIR} ${USER_PROJECT_HOME}/data
link_dir ${LOG_DIR} ${USER_PROJECT_HOME}/log
link_dir ${MODEL_DIR} ${USER_PROJECT_HOME}/models
link_dir ${NOTEBOOK_DIR} ${USER_PROJECT_HOME}/notebooks

# add application
trap "rm -rf ${USER_PROJECT_HOME}/application ${USER_PROJECT_HOME}/setup.py" EXIT
copy_not_existed ${current_home}/application ${USER_PROJECT_HOME}/application
copy_not_existed ${current_home} ${USER_PROJECT_HOME} setup.py

# start docker task
#: ${DRY_RUN:="yes"}
if is_yes ${IMAGE_EXISTED}; then
  use_existed ${DRY_RUN}
else
  build ${DRY_RUN}
fi
run ${DRY_RUN}
