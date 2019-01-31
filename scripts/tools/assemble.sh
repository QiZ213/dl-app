#!/bin/bash
# script to assemble user project

CURR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
. "${CURR_DIR}/../common_settings.sh"

if [[ $# -lt 1 ]]; then
  red_echo "Illegal arguments: ./assemble.sh target [source] [project_name] [git_branch]"
  exit 128
fi

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}

TARGET="$1"
shift
SOURCE="$1"
shift
PROJECT_NAME="$1"
shift
GIT_BRANCH="$1"


: ${TARGET:? TARGET should not be null}

# a normal dl-application project required components
TARGET_REQUIRED="application"
TARGET_REQUIRED+=" setup.py"
TARGET_REQUIRED+=" confs"
TARGET_REQUIRED+=" dockers"
TARGET_REQUIRED+=" resources"
TARGET_REQUIRED+=" requirements_service.txt"
TARGET_REQUIRED+=" requirements_train.txt"
TARGET_REQUIRED+=" scripts/common_settings.sh"
TARGET_REQUIRED+=" scripts/common_utils.sh"
TARGET_REQUIRED+=" scripts/start.sh"
TARGET_REQUIRED+=" scripts/start_notebook.sh"
TARGET_REQUIRED+=" scripts/start_service.sh"
TARGET_REQUIRED+=" scripts/installations"

# user project required components
SOURCE_REQUIRED="scripts/common_settings.sh"


assemble_components() {
  local src=$1
  local tgt=$2

  for i in $(ls -A ${src}); do
    case ${i} in
      requirements)
        copy_missing ${src}/${i}/${PROJECT_NAME} ${tgt}
        ;;
      confs|resources|scripts)
        # copy the contents of project_name_folder to target
        mute copy_missing ${src}/${i}/${PROJECT_NAME} ${tgt}/${i} \
          || copy_missing ${src} ${tgt} ${i}
        ;;
      *)
        copy_missing ${src} ${tgt} ${i}
        ;;
    esac
  done
}


# append resources dir which defined in common_settings.sh to user project
append_resources() {
  local src=${RESOURCE_DIR}
  local tgt=${TASK_HOME}/resources

  if [[ -d ${src} ]]; then
    copy_missing ${src} ${tgt} $(ls ${src})
    blue_echo "copy ${src} to ${tgt}"
  fi
}


check_required() {
  required=$(eval echo \$${1}_REQURIED)
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
    # fetch from local files
    assemble_components ${SOURCE} ${TARGET}
  else
    # fetch from git
    tmp_source="${TARGET}/dl-tmp"
    mkdir ${tmp_source}
    trap "rm -rf ${tmp_source}" RETURN EXIT
    git clone --recursive --depth=1 ${SOURCE} -b ${GIT_BRANCH} ${tmp_source}
    die_if_err "fail to fetch codes from ${SOURCE}"
    assemble_components ${tmp_source} ${TARGET}
  fi

  check_required "SOURCE" "${TARGET}"
  # copy missing components to target folder
  copy_missing ${current_home} ${TARGET} ${TARGET_REQUIRED}
else
  yellow_echo "${TARGET} already existed"
fi

check_required "TARGET" "${TARGET}"

. ${TARGET}/scripts/common_settings.sh
append_resources
