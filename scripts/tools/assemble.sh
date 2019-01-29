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

COMPONENT_ASSEMBLED="confs"
COMPONENT_ASSEMBLED+=" resources"
COMPONENT_ASSEMBLED+=" scripts"
COMPONENT_ASSEMBLED+=" requirements"


# there may be components with multiple code in user project
# , each of which corresponds to a project name.
get_component_folder() {
  local src=$1
  local cmpt=$2 # component

  if [[ -n ${cmpt} && -d "${src}/${cmpt}" ]]; then
    if [[ -n ${PROJECT_NAME} && -d "${src}/${cmpt}/${PROJECT_NAME}" ]]; then
      echo ${cmpt}/${PROJECT_NAME}
    else
      echo ${cmpt}
    fi
  else
    echo ""
  fi
}


assemble_components() {
  local src=$1
  local tgt=$2

  for cmpt in ${COMPONENT_ASSEMBLED}; do
    component_folder=$(get_component_folder ${src} ${cmpt})
    if [[ -z ${component_folder} ]]; then
      continue
    fi
    if [[ ${cmpt} == requirements ]]; then
      # for downward compatibility, requirements_*.txt in the root of project_home
      cp -r ${src}/${component_folder}/* ${tgt}
    else
      [[ -d ${tgt}/${cmpt} ]] || mkdir ${tgt}/${cmpt}
      cp -r ${src}/${component_folder}/* ${tgt}/${cmpt}
    fi
  done

  component_pattern=$(echo ${COMPONENT_ASSEMBLED} | sed 's/ /\|/g')  # replace components to be separated by a vertical line
  remains=$(ls ${src} | grep -vE ${component_pattern} | xargs)
  copy_missing ${src} ${tgt} ${remains}
  [[ -e ${src}/.git ]] && cp -r ${src}/.git ${tgt}
  [[ -e ${src}/.gitignore ]] && cp -r ${src}/.gitignore ${tgt}
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
    git clone --recursive --depth=1 ${SOURCE} -b ${GIT_BRANCH} ${tmp_source}
    die_if_err "fail to fetch codes from ${SOURCE}"
    assemble_components ${tmp_source} ${TARGET}
    rm -rf ${tmp_source}
  fi

  check_required "SOURCE" "${TARGET}"
  # copy missing components to target folder
  copy_missing ${current_home} ${TARGET} ${TARGET_REQUIRED}
else
  yellow_echo "${TARGET} already existed"
fi

check_required "TARGET" "${TARGET}"
