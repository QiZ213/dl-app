#!/bin/bash
curr_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
source ${curr_dir}/env.sh

DEVICE_TYPE=$1
PROJECT_NAME=$2 # e.g. "captcha-train"
PROJECT_VERSION=$3 # e.g. "0.1"

# docker settings
if [ ${DEVICE_TYPE} == "cpu" ] ; then
  DOCKER_ENGINE=docker
elif [ ${DEVICE_TYPE} == "gpu" ] ; then
  DOCKER_ENGINE=nvidia-docker
else
  echo "device_type, either cpu or gpu"
  exit 128
fi
DOCKER_HOME="/opt/${PROJECT_NAME}"
DOCKER_TAG="${PROJECT_NAME}:${PROJECT_VERSION}"
