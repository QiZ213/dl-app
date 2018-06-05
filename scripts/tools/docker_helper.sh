#!/bin/bash
# Script to help build and run docker images
. "${BASH_SOURCE%/*}/../common_settings.sh"

IDC_NAME=$1 # e.g. "ppd"
DEVICE_TYPE=$2  # e.g. "gpu"
PROJECT_NAME=$3 # e.g. "ocr-service"
PROJECT_VERSION=$4 # e.g. "0.1"

curr_dir=$(dirname $0)
. ${curr_dir}/deploy.sh ${PROJECT_NAME}

DOCKER=docker
DOCKER_HOME="/opt/${PROJECT_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"

if [[ ${IDC_NAME} == "ppd" ]]; then
  DOCKER_REGISTRY="dock.cbd.com:80"
  ${DOCKER} login -u admin -p admin123 ${DOCKER_REGISTRY}
elif [[ ${IDC_NAME} == "aws" ]] ; then
  DOCKER_REGISTRY="registry.ppdai.aws"
else
  echo "unsupported idc: ${IDC_NAME}"
  exit 64
fi

if [[ ${DEVICE_TYPE} == "cpu" ]]; then
  DOCKER_ENGINE=docker
  OS="cpu-${OS_VERSION}"
elif [[ ${DEVICE_TYPE} == "gpu" ]]; then
  DOCKER_ENGINE=nvidia-docker
  OS="gpu-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${OS_VERSION}"
else
  echo "invalid device_type, either cpu or gpu"
  exit 64
fi

if [[ "${PYTHON_VERSION}" == "2" ]]; then
  PYTHON_ALIAS="27"
elif [[ "${PYTHON_VERSION}" == "3" ]]; then
  PYTHON_ALIAS="36"
else
  echo "invalid python, either 2 or 3"
  exit 64
fi

# common docker-image building args
BUILDING_ARGS="--build-arg project_home_in_docker=${DOCKER_HOME}"
DOCKER_BASE="${DOCKER_REGISTRY}/${DEEP_LEARNING_FRAMEWORK}-py${PYTHON_ALIAS}-${OS}:${DEEP_LEARNING_DOCKER_VERSION}"
BUILDING_ARGS="${BUILDING_ARGS} --build-arg base=${DOCKER_BASE}"

# common docker-image running options
RUNNING_OPTIONS="-v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR}"
RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR}"
RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR}"

delete_docker_container() {
  if [[ $# != 1 ]]; then
    echo "Illegal arguments: delete_docker_container project_name"
    return 64
  fi
  ${DOCKER} ps -a | grep $1 &> /dev/null \
    && ${DOCKER} stop $1 &> /dev/null \
    && ${DOCKER} rm -v $1 &> /dev/null
  return 0
}

delete_docker_image() {
  if [[ $# != 1 ]]; then
    echo "Illegal arguments: delete_docker_image image_tag"
    return 64
  fi
  ${DOCKER} image inspect $1 &> /dev/null \
      && ${DOCKER} rmi $1 &> /dev/null
  return 0
}

check_application_status() {
  if [[ $# != 1 ]]; then
    echo "Illegal arguments: check_application_status project_name"
    return 64
  fi
  sleep 5s # ensure check status after initialization completed
  if $(${DOCKER} ps -a | grep $1 | grep "Exited" &> /dev/null); then
    echo "fail to start application, please debug"
    delete_docker_container $1
    return 64
  fi
  return 0
}
