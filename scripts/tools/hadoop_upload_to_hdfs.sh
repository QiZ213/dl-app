#!/bin/bash
if [[ $# -lt 2 ]]; then
  echo "Illegal arguments: hadoop_upload_to_hdfs.sh local remote"
  echo "e.g. /bin/bash hadoop_upload_to_hdfs.sh local_dir remote_dir"
  exit 128
fi

LOCAL_DIR=$1
HADOOP_DIR=$2

curr_dir=$(dirname $0)
. ${curr_dir}/hadoop_helpers.sh

HADOOP_PATH="${HADOOP_HOME}/${HADOOP_DIR}"
if check_and_remove_hadoop_output ${HADOOP_PATH}; then
  ${HADOOP} fs -put "${LOCAL_DIR}" "${HADOOP_PATH}" \
    || { echo "fail to upload data: ${LOCAL_DIR} to hdfs: ${HADOOP_PATH}" && exit 65; }
fi
echo "upload data done"

if generate_hadoop_success_tag ${HADOOP_PATH}; then
  echo "generate success tag done"
fi
