#!/bin/bash
# script to assemble user project
if [[ $# -lt 8 ]]; then
  red_echo "Illegal arguments: ./deploy.sh user_project_home dry_run idc_name device_type task_name task_version task_type image_existed [cmd]"
  echo "e.g. $ /bin/bash deploy.sh ~/poem no ppd|aws cpu|gpu poem 0.1 service|train|notebook|debug no [cmd]"
  exit 128
fi
CURR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. "${CURR_DIR}/../common_settings.sh"

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

USER_PROJECT_HOME="$1"
DRY_RUN="$2"
shift 2

TASK_NAME=$3
TASK_TYPE=$5
if [[ "${TASK_TYPE}" == init ]]; then
  blue_echo "init ${TASK_NAME} successfully"
  exit 0
fi

. ${USER_PROJECT_HOME}/scripts/common_settings.sh
. ${current_bin}/tools/docker_helpers.sh $@

# link external dir to user project
link_dir() {
  blue_echo "ln -s $1 $2"
  if not_yes "$3"; then
    [[ -d $1 ]] || mkdir -p $1
    [[ -d $2 ]] \
      || {
        rm -rf $2 && ln -s $1 $2;
        die_if_err "fail to link $1 to $2";
      }
  fi
}

default_base_dir=/opt
[[ -w ${default_base_dir} ]] || default_base_dir=~

: ${DATA_DIR:=${default_base_dir}/data/${PROJECT_NAME}}
: ${LOG_DIR:=${default_base_dir}/log/${PROJECT_NAME}}
: ${MODEL_DIR:=${default_base_dir}/models/${PROJECT_NAME}}
: ${NOTEBOOK_DIR:=${default_base_dir}/notebooks/${PROJECT_NAME}}

# link external dir
link_dir ${DATA_DIR} ${USER_PROJECT_HOME}/data ${DRY_RUN}
link_dir ${LOG_DIR} ${USER_PROJECT_HOME}/log ${DRY_RUN}
link_dir ${MODEL_DIR} ${USER_PROJECT_HOME}/models ${DRY_RUN}
link_dir ${NOTEBOOK_DIR} ${USER_PROJECT_HOME}/notebooks ${DRY_RUN}

# add application to user project
trap "rm -rf ${USER_PROJECT_HOME}/application ${USER_PROJECT_HOME}/setup.py" EXIT
copy_missing ${current_home}/application ${USER_PROJECT_HOME}
copy_missing ${current_home} ${USER_PROJECT_HOME} setup.py

# start docker task
build ${DRY_RUN}
run ${DRY_RUN}
