#!/bin/bash
# Script to help build and run docker images

IDC_NAME=$1 # e.g. "ppd"
DEVICE_TYPE=$2  # e.g. "gpu"
TASK_NAME=$3 # e.g. "ocr-service"
TASK_VERSION=$4 # e.g. "0.1"
TASK_TYPE=$5 # e.g. "debug"
IMAGE_EXISTED=$6 # e.g. "yes"
shift 6
CMD="$@"


DOCKER=docker
CHECK_MSG="please check ${PROJECT_BIN}/common_settings.sh"
EMPTY_ERR_MSG="should not be empty, ${CHECK_MSG}"

# check arguments
case "${IDC_NAME}" in
  "ppd") DOCKER_REGISTRY="dock.cbd.com:80"; mute ${DOCKER} login -u admin -p admin123 ${DOCKER_REGISTRY} ;;
  "aws") DOCKER_REGISTRY="registry.ppdai.aws" ;;
  *) die "unsupported idc: ${IDC_NAME}" ;;
esac

case "${DEVICE_TYPE}" in
  "cpu")
    DOCKER_ENGINE=docker
    SYSTEM="cpu"
    ;;
  "gpu")
    DOCKER_ENGINE=nvidia-docker
    : ${CUDA_VERSION:?CUDA_VERSION ${EMPTY_ERR_MSG}}
    : ${CUDNN_VERSION:?CUDNN_VERSION ${EMPTY_ERR_MSG}}
    SYSTEM="gpu-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}"
    ;;
  *) die "invalid device_type, either cpu or gpu" ;;
esac

case "${PYTHON_VERSION}" in
  "2") PYTHON_ALIAS="py27" ;;
  "3") PYTHON_ALIAS="py36" ;;
  *) test -f test; die_if_err "invalid python version ${PYTHON_VERSION}, either 2 or 3, ${CHECK_MSG}" ;;
esac

case "${TASK_TYPE}" in
  "service")
    DOCKER_FILE="./dockers/Dockerfile.service"
    CMD=""
    RUNNING_MODE="-d --restart=unless-stopped"
    RUNNING_OPTIONS="--net=bridge -p ${SERVING_PORT:=18080}:8080 ${RUNNING_OPTION}"
    ;;
  "train")
    DOCKER_FILE="./dockers/Dockerfile.train"
    BUILDING_ARGS="--build-arg train_user=$(whoami) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg train_uid=$(id -u) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg train_gid=$(id -g) ${BUILDING_ARGS}"
    RUNNING_MODE="-it"
    ;;
  "develop")
    DOCKER_FILE="./dockers/notebook/Dockerfile.ppd-notebook"
    BUILDING_ARGS="--build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456} ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_base_url=${TASK_NAME} ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_user=$(whoami) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_uid=$(id -u) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_gid=$(id -g) ${BUILDING_ARGS}"
    CMD="/bin/bash -c start_notebook.sh"
    RUNNING_MODE="-d --restart=unless-stopped"
    RUNNING_OPTIONS="-v ${PROJECT_HOME}:/home/$(whoami)"
    RUNNING_OPTIONS="-p ${NOTEBOOK_PORT:=18888}:8888 ${RUNNING_OPTIONS}"
    ;;
  "notebook")
    DOCKER_FILE="./dockers/notebook/Dockerfile.ppd-notebook"
    BUILDING_ARGS="--build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456} ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_base_url=${TASK_NAME} ${BUILDING_ARGS} "
    BUILDING_ARGS="--build-arg notebook_user=$(whoami) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_uid=$(id -u) ${BUILDING_ARGS}"
    BUILDING_ARGS="--build-arg notebook_gid=$(id -g) ${BUILDING_ARGS}"
    CMD="/bin/bash -c start_notebook.sh"
    RUNNING_MODE="-d --restart=unless-stopped"
    RUNNING_OPTIONS="-v ${PROJECT_HOME}/notebooks:/home/$(whoami)"
    RUNNING_OPTIONS="-p ${NOTEBOOK_PORT:=18888}:8888 ${RUNNING_OPTIONS}"
    ;;
  "debug")
    IMAGE_EXISTED="yes"
    CMD="/bin/bash"
    RUNNING_MODE="-it"
    RUNNING_OPTIONS="--net=bridge -p ${SERVING_PORT:=18080}:8080"
    ;;
  *) die "unsupported task type: ${TASK_TYPE}" ;;
esac

: ${OS_VERSION:?OS_VERSION ${EMPTY_ERR_MSG}}
: ${DEEP_LEARNING_FRAMEWORK:?DEEP_LEARNING_FRAMEWORK ${EMPTY_ERR_MSG}}
: ${DEEP_LEARNING_VERSION:?DEEP_LEARNING_VERSION ${EMPTY_ERR_MSG}}

DOCKER_HOME="/opt/${TASK_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"

DOCKER_TAG="${TASK_NAME}:${TASK_VERSION}"
DOCKER_BASE="${DOCKER_REGISTRY}/${DEEP_LEARNING_FRAMEWORK}:${DEEP_LEARNING_VERSION}-${PYTHON_ALIAS}-${SYSTEM}-${OS_VERSION}"

BUILDING_ARGS="--build-arg project_home_in_docker=${DOCKER_HOME} ${BUILDING_ARGS}"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE} ${BUILDING_ARGS}"
BUILDING_ARGS="--build-arg project_name=${TASK_NAME} ${BUILDING_ARGS}"
BUILD_CMD="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${PROJECT_HOME}"

RUNNING_OPTIONS="-v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR} ${RUNNING_OPTIONS}"
RUNNING_OPTIONS="-v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR} ${RUNNING_OPTIONS}"
RUNNING_OPTIONS="-v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR} ${RUNNING_OPTIONS}"
RUN_CMD="${DOCKER_ENGINE} run ${RUNNING_MODE} --name ${TASK_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"

is_image_existed() {
  mute ${DOCKER} image inspect "$1"
}

delete_image() {
  if is_image_existed "$1"; then
    mute ${DOCKER} rmi -f "$1"
    die_if_err "fail to delete image $1"
  fi
}

is_container_existed() {
  ${DOCKER} ps -a | mute grep "$1"
}

delete_container() {
  if is_container_existed "$1"; then
    mute ${DOCKER} stop "$1" && mute ${DOCKER} rm -v -f "$1"
    die_if_err "fail to delete container $1"
  fi
}

is_container_running(){
  ${DOCKER} ps -a -f status=running | mute grep "$1"
}

use_existed() {
  if ! is_image_existed ${DOCKER_TAG}; then
    pull_cmd="${DOCKER} pull ${DOCKER_REGISTRY}/${DOCKER_TAG}"
    tag_cmd="${DOCKER} tag ${DOCKER_REGISTRY}/${DOCKER_TAG} ${DOCKER_TAG}"
    cmd="${pull_cmd} && ${tag_cmd}"
    blue_echo "${cmd}"
    if not_yes "$1" ; then
      mute eval ${cmd}
      die_if_err "fail to fetch ${DOCKER_TAG} from ${DOCKER_REGISTRY}"
    fi
  fi
  echo "use existed image ${DOCKER_TAG}"
}

build() {
  if is_yes "${IMAGE_EXISTED}"; then
    use_existed "$1"
  else
    echo "building image ${DOCKER_TAG} by:"
    blue_echo "${BUILD_CMD}"
    if not_yes "$1"; then
      delete_image ${DOCKER_TAG}
      eval ${BUILD_CMD}
      die_if_err "fail to build image ${DOCKER_TAG}"
    fi
    echo "build ${DOCKER_TAG} successfully"
  fi
}

run() {
  echo "running image ${DOCKER_TAG} in ${TASK_TYPE} mode by:"
  blue_echo "${RUN_CMD}"
  if not_yes "$1" ; then
    delete_container ${TASK_NAME}
    eval ${RUN_CMD}
    die_if_err "failed to run container ${DOCKER_TAG}"
    echo ${TASK_TYPE}
    if [[ "${TASK_TYPE}" != "debug" && "${TASK_TYPE}" != "train" ]]; then
      is_container_running ${TASK_NAME} || {
        delete_container ${TASK_NAME};
        die "container ${DOCKER_TAG} not running";
      }
    fi
  fi
  echo "start ${DOCKER_TAG} successfully"
}