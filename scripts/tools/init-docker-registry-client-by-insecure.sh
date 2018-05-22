#!/bin/bash
if [ $# -lt 3 ]; then
  echo "Illegal arguments: init-docker-registry-client-by-insecure.sh registry_ip registry_name os"
  echo "e.g. $ /bin/bash init-docker-registry-client.sh 10.1.62.214 dock.cbd.com:80 linux"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/../common-settings.sh

REGISTRY_IP=$1
REGISTRY_NAME=$2
OS=$3

if [ ${OS} == 'linux' ]; then
  DOCKER_DAEMON=/etc/docker/daemon.json
  DOCKER_INSECURE_REGISTRIES="  \"insecure-registries\" : [ \"${REGISTRY_NAME}\" ]"
  if $(sudo test -f ${DOCKER_DAEMON}); then
    sudo grep "${REGISTRY_NAME}" ${DOCKER_DAEMON} &> /dev/null \
        && echo "insecure registry already in docker daemon" && exit 0
    echo "add ${DOCKER_INSECURE_REGISTRIES} to ${DOCKER_DAEMON} and restart docker manually"
  else
    sudo touch ${DOCKER_DAEMON}
    echo "{${DOCKER_INSECURE_REGISTRIES}}" | sudo tee ${DOCKER_DAEMON}
    sudo service docker restart
  fi
elif [ ${OS} == 'mac' ]; then
  echo "open docker app, choose \"Daemon\" tab, "
  echo "add \"dock.cbd.com:80\" to Insecure registries, "
  echo "and restart docker service manually."
else
  echo "unsupported os: ${OS}"
  exit 64
fi

