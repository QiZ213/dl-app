#!/bin/bash

CURR_DIR=$(cd $(dirname ${BASH_SOURCE}); pwd)
CURR_HOME=$(cd $(dirname ${CURR_DIR}); pwd)

. "${CURR_DIR}/common_settings.sh"

if [[ $# -lt 1 ]]; then
  red_echo "Illegal argument. e.g. bash init.sh source_path [--service]"
  exit 1
fi

SOURCE=$1
shift 1

: ${SOURCE?"SOURCE is requied, need path, got null."}

# source required components
source_required="scripts/common_settings.sh"

while [[ -n "$1" && "$1" =~ ^-.* ]]; do
  echo $1
  case "$1" in
    --service)
      source_required+=" confs"
      source_required+=" requirements_service.txt"
      shift 1
    ;;
    --all)
      source_required+=" confs"
      source_required+=" dockers"
      source_required+=" resources"
      source_required+=" requirements_service.txt"
      source_required+=" requirements_train.txt"
      source_required+=" scripts/common_utils.sh"
      source_required+=" scripts/start.sh"
      source_required+=" scripts/start_notebook.sh"
      source_required+=" scripts/start_service.sh"
      shift 1
     ;;
    *) break ;;
  esac
done


if [[ ! -d ${SOURCE} ]]; then
  mkdir -p ${SOURCE}
fi

copy_missing ${CURR_HOME} ${SOURCE} ${source_required}

echo "init ${SOURCE} successfully"
green_echo "1. Please edit ${SOURCE}/scripts/common_settings.sh"
green_echo "2. For notebook or train task, "
green_echo "  please edit ${SOURCE}/requirements_train.txt ."
green_echo "   For service task, "
green_echo "  please edit ${SOURCE}/requirements_service.txt and ${SOURCE}/confs/conf.json ."
exit 0
