#!/bin/bash
# script to assemble user project
if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh target [source] [git_branch]"
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
GIT_BRANCH="$1"

if [[ -e ${TARGET} ]]; then
  blue_echo "${TARGET} already existed"
else
  # setup user project
  mkdir -p ${TARGET}
  if [[ -n "${SOURCE}" ]]; then
    if [[ -d ${SOURCE} ]]; then
      # fetch from source
      [[ -d ${SOURCE}/scripts ]] && cp -r ${SOURCE}/* ${TARGET} \
        || cp -r ${SOURCE} ${TARGET}
    else
      # fetch from git
      git clone ${SOURCE} -b ${GIT_BRANCH} ${TARGET}
      die_if_err "fail to fetch codes from ${SOURCE}"
    fi
  fi

  # copy missing components to user project
  copy_missing ${current_home}/confs ${TARGET}
  copy_missing ${current_home}/dockers ${TARGET}
  copy_missing ${current_home} ${TARGET} requirements*
  copy_missing ${current_home}/scripts ${TARGET}/scripts start*.sh
  if [[ ! -f ${TARGET}/scripts/common_settings.sh ]]; then
    copy_missing ${current_home}/scripts ${TARGET}/scripts common*.sh
    blue_echo "Please edit ${TARGET}/scripts/common_setting.sh"
    blue_echo "For notebook or train task, "
    blue_echo "  please edit ${TARGET}/requirements_train.txt ."
    blue_echo "For service task, "
    blue_ehco "  please edit ${TARGET}/requirements_service.txt and ${TARGET}/confs/conf.json ."
    exit 0
  fi
fi

