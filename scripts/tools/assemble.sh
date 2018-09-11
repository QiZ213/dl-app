#!/bin/bash
# script to assemble user project
if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh target [source] [git_base] [git_branch]"
  exit 128
fi
CURR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. "${CURR_DIR}/../common_settings.sh"

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

TARGET="$1"
shift
SOURCE="$1"
shift
GIT_BASE="$1"
shift
GIT_BRANCH="$1"

if [[ -e ${TARGET} ]]; then
  blue_echo "${TARGET} already existed"
  exit 0
fi

if [[ -d ${SOURCE} ]]; then
  [[ -d ${SOURCE}/scripts ]] && cp -r ${SOURCE}/* ${TARGET}/ \
    || cp ${SOURCE} ${TARGET}
else
  : ${GIT_BASE:?GIT_BASE should not be empty}
  : ${GIT_BRANCH:?GIT_BRANCH should not be empty}
  GIT_PATH=${GIT_BASE}/${SOURCE}
  git clone ${GIT_PATH} -b ${GIT_BRANCH} ${TARGET}
  die_if_err "fail to fetch codes from ${GIT_PATH}"
fi

# copy missing components to user project
copy_missing ${current_home}/confs ${TARGET}
copy_missing ${current_home}/dockers ${TARGET}
copy_missing ${current_home} ${TARGET} requirements_*

if [[ ! -f ${TARGET}/scripts/common_settings.sh ]]; then
  copy_missing ${current_home}/scripts ${TARGET}/scripts \
    common_settings.sh common_utils.sh start_service.sh
  blue_echo "Please edit ${TARGET}/scripts/common_setting.sh"
  blue_echo "Please also edit ${TARGET}/confs/conf.json if you want to start a service"
  exit 1
fi

