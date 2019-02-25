#!/bin/bash
# script to assemble target project
curr_dir=$(dirname ${BASH_SOURCE[0]})
. "${curr_dir}/../common_settings.sh"

if [[ $# -lt 2 ]]; then
  red_echo "Illegal arguments: ./assemble.sh source_path target_path"
  exit 128
fi

SOURCE_PATH="$1"
TARGET_PATH="$2"

PROJECT_NAME=$(basename ${TARGET_PATH})

# required components for target distribution to fit dl-application framework
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

assemble() {
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

check_required() {
  local src=$1
  shift 1

  for i in $@; do
    [[ -e "${src}/${i}" ]] || die "${src} missing required files: ${i}"
  done
}

if [[ ! -e ${TARGET_PATH} ]]; then
  assemble ${SOURCE_PATH} ${TARGET_PATH}
  copy_missing ${PROJECT_HOME} ${TARGET_PATH} ${TARGET_REQUIRED}
else
  yellow_echo "${TARGET_PATH} already existed"
fi

check_required ${TARGET_PATH} ${TARGET_REQUIRED}
