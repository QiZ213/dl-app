#!/bin/bash
# Script to help process with hadoop
. "${BASH_SOURCE%/*}/../common_settings.sh"

HADOOP="hadoop"
HADOOP_HOME="/user/$(whoami)"

check_and_remove_hadoop_output(){
  if [[ $# -ne 1 ]]; then
    echo "usage: check_and_remove_hadoop_output dir"
    exit 64
  fi
  dir=$1
  ${HADOOP} fs -test -d ${HADOOP_PATH} \
    && ${HADOOP} fs -rm -r -f ${HADOOP_PATH} &> /dev/null \
    || { echo "fail to check and remove ${dir}" && return 65; }
  return 0
}

generate_hadoop_success_tag(){
  if [[ $# -ne 1 ]]; then
    echo "usage: generate_hadoop_success_tag dir"
    exit 64
  fi
  dir=$1
  ${HADOOP} fs -test -d ${dir} \
    && ! ${HADOOP} fs -test -e ${dir}/_SUCCESS \
    && ${HADOOP} fs -touchz ${dir}/_SUCCESS \
    || { echo "fail to generate success tag for ${dir}" && return 65; }
  return 0
}
