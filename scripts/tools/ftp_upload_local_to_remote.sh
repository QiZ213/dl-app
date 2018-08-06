#!/bin/bash
if [[ $# -lt 2 ]]; then
  echo "Illegal arguments: ftp_upload_local_to_remote.sh local remote"
  echo "e.g. /bin/bash ftp_upload_local_to_remote.sh local_dir remote_dir"
  exit 128
fi

LOCAL_DIR=$1
REMOTE_DIR=$2

curr_dir=$(dirname $0)
. ${curr_dir}/ftp_helpers.sh

LOCAL_SUCCESS_TAG=${LOCAL_DIR}/_SUCCESS
test -e ${LOCAL_SUCCESS_TAG} \
  || { echo "${LOCAL_SUCCESS_TAG} not existed" && exit 65; }

MIRROR_LOCAL_TO_REMOTE="${FTP_CMD_BASE} mirror -R ${LOCAL_DIR} ${REMOTE_DIR}; exit"
${FTP} -e "${MIRROR_LOCAL_TO_REMOTE}" \
  || { echo "fail to upload data from ${LOCAL_DIR} to ${REMOTE_DIR}" && exit 66; }
echo "upload data done"
