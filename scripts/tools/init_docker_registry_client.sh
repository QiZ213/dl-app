#!/bin/bash
if [[ $# -lt 2 ]]; then
  echo "Illegal arguments: init_docker_registry_client.sh idc os [remote_certs]"
  echo "e.g. $ /bin/bash init_docker_registry_client.sh ppd|aws linux|mac [/opt/dl-dockers/certs]"
  exit 128
fi
. "${BASH_SOURCE%/*}/../common_settings.sh"

IDC_NAME=$1
OS=$2
REMOTE_CERTS_DIR=$3

if [[ ${IDC_NAME} == 'ppd' ]]; then
  DOCKER_REGISTRY="dock.cbd.com:80"
  DOCKER_IP="10.1.62.214"
elif [[ ${IDC_NAME} == 'aws' ]]; then
  DOCKER_REGISTRY="registry.ppdai.aws"
  DOCKER_IP="172.31.14.82"
else
  echo "unsupported idc: ${IDC_NAME}"
  exit 64
fi

if [[ ! -z "${REMOTE_CERTS_DIR}" ]]; then
  . ${curr_dir}/init_docker_registry_client_by_certs.sh \
    ${DOCKER_IP} \
    ${DOCKER_REGISTRY} \
    ${OS} \
    "$(whoami)@${DOCKER_IP}:${REMOTE_CERTS_DIR}"
else
   . ${curr_dir}/init_docker_registry_client_by_insecure.sh \
     ${DOCKER_IP} \
     ${DOCKER_REGISTRY} \
     ${OS}
fi

# add dns to /etc/hosts
sudo grep "${DOCKER_IP} ${DOCKER_REGISTRY%%:*}" /etc/hosts &> /dev/null \
  || echo "${DOCKER_IP} ${DOCKER_REGISTRY%%:*}" | sudo tee -a /etc/hosts
