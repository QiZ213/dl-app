#!/bin/bash
# script to assemble user project

CURR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. "${CURR_DIR}/../common_settings.sh"

if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh target [source] [git_branch]"
  exit 128
fi

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

TARGET="$1"
shift
SOURCE="$1"
shift
GIT_BRANCH="$1"

: ${TARGET:? TARGET should not be null}

# a normal dl-application project required components
target_required="confs"
target_required+=" dockers"
target_required+=" resources"
target_required+=" requirements_service.txt"
target_required+=" requirements_train.txt"
target_required+=" scripts/common_settings.sh"
target_required+=" scripts/common_utils.sh"
target_required+=" scripts/start.sh"
target_required+=" scripts/start_notebook.sh"
target_required+=" scripts/start_service.sh"

# user project required components
source_required="scripts/common_settings.sh"

check_required() {
  required=$(eval echo \$${1}_required)
  src=$2
  for sub_path in ${required}; do
    [[ -e "${src}/${sub_path}" ]]
    die_if_err "${1} missing required files: ${sub_path}. Read documents about \"${1} required\"."
  done
}

if [[ ! -e ${TARGET} ]]; then
  # setup user project
  mkdir -p ${TARGET}
  if [[ -d ${SOURCE} ]]; then
    # fetch from source
    cp -r ${SOURCE}/* ${TARGET}
    [[ -e ${SOURCE}/.git ]] && cp -r ${SOURCE}/.git ${TARGET}
  else
    # fetch from git
    git clone --depth=1 ${SOURCE} -b ${GIT_BRANCH} ${TARGET}
    die_if_err "fail to fetch codes from ${SOURCE}"
  fi
  check_required "source" "${TARGET}"
  # copy missing components to target folder
  copy_missing ${current_home} ${TARGET} ${target_required}
else
  yellow_echo "${TARGET} already existed"
fi

check_required "target" "${TARGET}"
