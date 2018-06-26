#!/bin/bash
if [[ $# -lt 2 ]]; then
  echo "Illegal arguments: ftp_download_remote_to_local.sh remote local"
  echo "e.g. /bin/bash ftp_download_remote_to_local.sh remote_dir local_dir"
  exit 128
fi

REMOTE_DIR=$1
LOCAL_DIR=$2

curr_dir=$(dirname $0)
. ${curr_dir}/ftp_helpers.sh

REMOTE_SUCCESS_TAG=${REMOTE_DIR}/_SUCESS
SUCCESS_COND="$(${FTP} -e "ls ${REMOTE_DIR}/_SUCCESS; exit")"
SUCCESS_ACT="echo ${REMOTE_SUCCESS_TAG} existed"
wait_for_condition 20 1s "${SUCCESS_COND}" "${SUCCESS_ACT}" \
  || { echo "${REMOTE_SUCCESS_TAG} not ready" && exit 66; }

MIRROR_REMOTE_TO_LOCAL="${FTP_CMD_BASE} mirror ${REMOTE_DIR} ${LOCAL_DIR}; exit"
${FTP} -e "${MIRROR_REMOTE_TO_LOCAL}" \
  || { echo "fail to download data from ${REMOTE_DIR} to ${LOCAL_DIR}" && exit 66; }
echo "download data done"
