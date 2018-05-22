#!/bin/bash
# Script to help build and run docker images
. "${BASH_SOURCE%/*}/../common-settings.sh"

IDC_NAME=$1 # e.g. "prod"
DEVICE_TYPE=$2  # e.g. "gpu"
PROJECT_NAME=$3 # e.g. "ocr-service"
PROJECT_VERSION=$4 # e.g. "0.1"

DOCKER=docker
if [ ${IDC_NAME} == "prod" ]; then
  DOCKER_REGISTRY="dock.cbd.com:80"
  ${DOCKER} login -u admin -p admin123 ${DOCKER_REGISTRY}
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

if [ "${PYTHON##/*/}" == "python3" ]; then
  DOCKER_BASE=
elif [ "${PYTHON##/*/}" == "python" ]; then
  DOCKER_BASE=${DOCKER_REGISTRY}/pytorch-py27-gpu-cuda8.0-cudnn5-ubuntu14.04:0.1
else
  echo "invalid python, either 2 or 3"
  exit 64
fi

DOCKER_HOME="/opt/${PROJECT_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"
DOCKER_TAG="${PROJECT_NAME}:${PROJECT_VERSION}"

# common docker-image building args
BUILDING_ARGS="--build-arg project_home_in_docker=${DOCKER_HOME}"
BUILDING_ARGS="${BUILDING_ARGS} --build-arg base=${DOCKER_BASE}"
BUILDING_ARGS="${BUILDING_ARGS} --build-arg data_dir_in_docker=${DOCKER_DATA_DIR}"
BUILDING_ARGS="${BUILDING_ARGS} --build-arg log_dir_in_docker=${DOCKER_LOG_DIR}"
BUILDING_ARGS="${BUILDING_ARGS} --build-arg model_dir_in_docker=${DOCKER_MODEL_DIR}"

# common docker-image running options
RUNNING_OPTIONS="-v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR}"
RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR}"
RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR}"


delete_docker_image() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: delete_docker_image image_tag"
    return 64
  fi
  ${DOCKER} image inspect $1 &> /dev/null \
      && ${DOCKER} rmi $1 &> /dev/null
  return 0
}


delete_docker_container() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: delete_docker_container project_name"
    return 64
  fi
  ${DOCKER} ps -a | grep $1 &> /dev/null \
      && ${DOCKER} stop $1 &> /dev/null \
      && ${DOCKER} rm -v $1 &> /dev/null
  return 0
}


check_application_status() {
  if [ $# != 1 ]; then
    echo "Illegal arguments: check_application_status project_name"
    return 64
  fi
  sleep 5s # ensure check status after initialization completed
  if ${DOCKER} ps -a | grep $1 | grep "Exited" &> /dev/null ; then
    echo "fail to start application, please debug"
    delete_docker_container $1
    return 64
  fi
  return 0
}
