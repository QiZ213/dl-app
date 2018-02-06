#!/bin/bash
. "${BASH_SOURCE%/*}/../common-settings.sh"

IDC_NAME=$1 # e.g. "prod"
DEVICE_TYPE=$2  # e.g. "cpu"
PROJECT_NAME=$3 # e.g. "captcha-train"
PROJECT_VERSION=$4 # e.g. "0.1"

if [ ${IDC_NAME} == "prod" ]; then
  DOCKER_REGISTRY="registry.ppdai.com"
elif [ ${IDC_NAME} == "aws" ] ; then
  DOCKER_REGISTRY="registry.ppdai.aws"
else
  echo "unsupported idc: ${IDC_NAME}"
  exit 64
fi

if [ ${DEVICE_TYPE} == "cpu" ]; then
  DOCKER_ENGINE=docker
elif [ ${DEVICE_TYPE} == "gpu" ]; then
  DOCKER_ENGINE=nvidia-docker
else
  echo "invalid device_type, either cpu or gpu"
  exit 64
fi

DOCKER=docker
DOCKER_HOME="/opt/${PROJECT_NAME}"
# DOCKER_BASE=${DOCKER_REGISTRY}/ppd-${DEVICE_TYPE}-base:${PROJECT_VERSION}
DOCKER_BASE=ppd-${DEVICE_TYPE}-base:${PROJECT_VERSION}
DOCKER_TAG="${PROJECT_NAME}:${PROJECT_VERSION}"

delete_docker_container() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: delete_docker_container project_name"
    return 64
  fi
  ${DOCKER} ps -a | grep $1 && ${DOCKER} stop $1 && ${DOCKER} rm -v $1
}

delete_docker_image() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: delete_docker_image image_tag"
    return 64
  fi
  ${DOCKER} image inspect $1 &> /dev/null && ${DOCKER} rmi $1
}

