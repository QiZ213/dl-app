#!/bin/bash
# Script to deploy project

curr_dir=$(dirname $0)
. ${curr_dir}/../common-settings.sh

check_dir() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: check_dir dir_name"
    return 64
  fi
  test -d $1 || mkdir -p $1
  return 0
}

check_dir ${DATA_DIR} || exit 64
check_dir ${LOG_DIR} || exit 64
check_dir ${MODEL_DIR} || exit 64
check_dir ${NOTEBOOK_DIR} || exit 64
