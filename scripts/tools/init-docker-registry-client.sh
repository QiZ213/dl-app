#!/bin/bash
if [ $# -lt 2 ]; then
  echo "Illegal arguments: init-docker-registry-client.sh idc os [remote_certs]"
  echo "e.g. $ /bin/bash init-docker-registry-client.sh ppd|aws linux|mac [/opt/dl-dockers/certs]"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/../common-settings.sh

IDC_NAME=$1
OS=$2
REMOTE_CERTS_DIR=$3

if [ ${IDC_NAME} == 'ppd' ]; then
  DOCKER_REGISTRY="dock.cbd.com:80"
  DOCKER_IP="10.1.62.214"
elif [ ${IDC_NAME} == 'aws' ]; then
  DOCKER_REGISTRY="registry.ppdai.aws"
  DOCKER_IP="172.31.14.82"
else
  echo "unsupported idc: ${IDC_NAME}"
  exit 64
fi

if [ ! -z "${REMOTE_CERTS_DIR}" ]; then
  . ${curr_dir}/init-docker-registry-client-by-certs.sh \
      ${DOCKER_IP} \
      ${DOCKER_REGISTRY} \
      ${OS} \
      "$(whoami)@${DOCKER_HOST}:${REMOTE_CERTS_DIR}"
else
   . ${curr_dir}/init-docker-registry-client-by-insecure.sh \
      ${DOCKER_IP} \
      ${DOCKER_REGISTRY} \
      ${OS}
fi

# add to /etc/hosts
sudo grep "${DOCKER_HOST} ${DOCKER_REGISTRY%%:*}" /etc/hosts &> /dev/null \
  || echo "please add \"${DOCKER_HOST} ${DOCKER_REGISTRY%%*.}\" to /etc/hosts manually"
