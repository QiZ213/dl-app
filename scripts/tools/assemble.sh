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
#source_required+=" requirements_service.txt"
#source_required+=" requirements_train.txt"

rm_target_if_die() {
  err_code=$?
  if [[ ${err_code} -ne 0 ]]; then
    rm -rf ${TARGET}
    die "$@"
  fi
}

check_validation() {
  required=$(eval echo \$${1}_required)
  src=$2
  for sub_path in ${required}; do
    [[ -e "${src}/${sub_path}" ]]
    rm_target_if_die "${1} missing required files: ${src}/${sub_path}. Read documents about \"${1} required\"."
  done
}

if [[ -e ${TARGET} ]]; then
  check_validation "target" "${TARGET}"
  yellow_echo "${TARGET} already existed"
else
  # setup user project
  mkdir -p ${TARGET}
  if [[ -n "${SOURCE}" ]]; then
    if [[ -d ${SOURCE} ]]; then
      # fetch from source
      check_validation "source" "${SOURCE}"
      cp -r ${SOURCE}/* ${TARGET}
      [[ -e ${SOURCE}/.git ]] && cp -r ${SOURCE}/.git ${TARGET}
    else
      # fetch from git
      git clone --depth=1 ${SOURCE} -b ${GIT_BRANCH} ${TARGET}
      die_if_err "fail to fetch codes from ${SOURCE}"
      check_validation "source" "${TARGET}"
    fi
  else
    both_null="yes"
  fi

  # copy missing components to target folder
  for sub_path in ${target_required}; do
    if echo ${sub_path%/} | grep -q "/"; then  # if exist multi_sub folder
      parent_path=${sub_path%/*}
      last_path=${sub_path##*/}
      copy_missing ${current_home}/${parent_path} ${TARGET}/${parent_path} ${last_path}
    else
      copy_missing ${current_home}/${sub_path} ${TARGET}
    fi
  done

  if [[ ${both_null} == "yes" ]]; then
    blue_echo "1. Please edit ${TARGET}/scripts/common_settings.sh"
    blue_echo "2. For notebook or train task, "
    blue_echo "  please edit ${TARGET}/requirements_train.txt ."
    blue_echo "   Or, for service task, "
    blue_echo "  please edit ${TARGET}/requirements_service.txt and ${TARGET}/confs/conf.json ."
    exit 0
  fi
fi

