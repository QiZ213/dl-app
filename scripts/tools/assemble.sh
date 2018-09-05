#!/bin/bash
# script to assemble user project
if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh project_name [source_path]"
  exit 128
fi

CURR_DIR=$(dirname $0)
. "${CURR_DIR}/../common_settings.sh"

PROJECT_NAME="$1"
shift
SOURCE_PATH="$1"

export USER_PROJECT_HOME=${PROJECT_HOME}/${PROJECT_NAME}

# fetch user project from source
if [[ ! -e ${USER_PROJECT_HOME} ]]; then
  mkdir -p ${USER_PROJECT_HOME}
  die_if_err "cannot create project dir ${USER_PROJECT_HOME}"

  if [[ -d ${SOURCE_PATH}/scripts ]]; then
    cp -r ${SOURCE_PATH}/* ${USER_PROJECT_HOME}
    die_if_err "fail to copy ${SOURCE_PATH}/* to ${USER_PROJECT_HOME}"
  fi

  if [[ ! -d ${SOURCE_PATH}/scripts ]] && [[ -d ${SOURCE_PATH} ]]; then
    cp -r ${SOURCE_PATH} ${USER_PROJECT_HOME}
    die_if_err "fail to copy ${SOURCE_PATH} to ${USER_PROJECT_HOME}"
  fi

  if [[ ! -d ${SOURCE_PATH} ]]; then
    : ${GIT_BASE:?GIT_BASE should not be empty}
    git clone ${GIT_BASE}/${SOURCE_PATH} ${USER_PROJECT_HOME}
    die_if_err "fail to fetch codes from ${GIT_BASE}/${SOURCE_PATH}"
  fi
fi

# copy missing components to user project
copy_not_existed ${PROJECT_HOME}/confs ${USER_PROJECT_HOME}/confs
copy_not_existed ${PROJECT_HOME}/dockers ${USER_PROJECT_HOME}/dockers
copy_not_existed ${PROJECT_HOME}/resources ${USER_PROJECT_HOME}/resources
copy_not_existed ${PROJECT_HOME} ${USER_PROJECT_HOME} requirements_*

# check common_settings.sh in user project
if [[ ! -f ${USER_PROJECT_HOME}/scripts/common_settings.sh ]]; then
  copy_not_existed ${PROJECT_HOME}/scripts ${USER_PROJECT_HOME}/scripts \
    common_settings.sh common_utils.sh start_service.sh
  blue_echo "Please edit ${USER_PROJECT_HOME}/scripts/common_setting.sh"
  exit 0
fi

