#!/bin/bash
# script to assemble user project
if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh user_project_path [source_path]"
  exit 128
fi
CURR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. "${CURR_DIR}/../common_settings.sh"

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

USER_PROJECT_HOME="$1"
shift
SOURCE_PATH="$1"

# fetch user project from source
if [[ ! -e ${USER_PROJECT_HOME} ]]; then
  if [[ -d ${SOURCE_PATH}/scripts ]]; then
    mkdir -p ${USER_PROJECT_HOME} && cp -r ${SOURCE_PATH}/* ${USER_PROJECT_HOME}
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
USER_PROJECT_HOME="$(absolute_path ${USER_PROJECT_HOME})"

# copy missing components to user project
copy_missing ${current_home}/confs ${USER_PROJECT_HOME}/confs
copy_missing ${current_home}/dockers ${USER_PROJECT_HOME}/dockers
copy_missing ${current_home}/resources ${USER_PROJECT_HOME}/resources
copy_missing ${current_home} ${USER_PROJECT_HOME} requirements_*

if [[ ! -f ${USER_PROJECT_HOME}/scripts/common_settings.sh ]]; then
  copy_missing ${current_home}/scripts ${USER_PROJECT_HOME}/scripts \
    common_settings.sh common_utils.sh start_service.sh
  blue_echo "Please edit ${USER_PROJECT_HOME}/scripts/common_setting.sh"
  blue_echo "Please also edit ${USER_PROJECT_HOME}/confs/conf.json if you want to start a service"
  exit 0
fi

