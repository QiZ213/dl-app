#!/bin/bash
# Script to help build and run docker images

TASK_NAME=$1 # e.g. "poem-service"
TASK_VERSION=$2 # e.g. "0.1"
DOCKER_TAG=$3 # e.g. "poem-service:0.1"
TASK_TYPE=$4 # e.g. "debug"
DEVICE_TYPE=$5  # e.g. "gpu" or "cpu"
REGISTRY_IDC=$6 # e.g. "aws" or "ppd"
DRY_RUN=$7 # e.g. "yes"
shift 7
CMD="$@"

DOCKER=docker
DOCKER_REGISTRIES=

PPD_REGISTRY="dock.cbd.com:80"
PPD_REGISTRY_USER="admin"
PPD_REGISTRY_PASSWORD="admin123"
PPD_REGISTRY_LOGIN_CMD="${DOCKER} login -u ${PPD_REGISTRY_USER} -p ${PPD_REGISTRY_PASSWORD} ${PPD_REGISTRY}"
DOCKER_REGISTRIES+=" ${PPD_REGISTRY}"

AWS_REGISTRY="registry.ppdai.aws:5000"
DOCKER_REGISTRIES+=" ${AWS_REGISTRY}"

DOCKER_HOME="/opt/${TASK_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"

EMPTY_ERR_MSG="should not empty, please check common_settings.sh under target"

lazy_run() {
  if not_yes "${DRY_RUN}"; then
    blue_echo "running: $@"
    eval $@
    die_if_err "fail to run: $@"
  fi
  blue_echo "done: $@"
}

login_registry() {
  [[ $# != 1 ]] && die "Usage, login_registry registry"
  if [[ "$1" == "${PPD_REGISTRY}" ]];then
    mute eval ${PPD_REGISTRY_LOGIN_CMD}
  fi
}

is_registry_available() {
  [[ $# != 1 ]] && die "Usage, is_registry_available registry"
  mute curl --connect-timeout 1 --silent --insecure $1/v2/_catalog
}

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
  mute ${DOCKER} container inspect "$1"
}

delete_container() {
  if is_container_existed "$1"; then
    mute ${DOCKER} stop "$1" && mute ${DOCKER} rm -v -f "$1"
    die_if_err "fail to delete container $1"
  fi
}

is_container_running() {
  ${DOCKER} container inspect "$1" | grep -q "\"Running\": true"
}

parse_device_type(){
  DOCKER_ENGINE=
  SYSTEM=
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
    *) die "invalid device_type ${DEVICE_TYPE}, either cpu or gpu" ;;
  esac
}

parse_python() {
  : ${PYTHON_VERSION:?PYTHON_VERSION ${EMPTY_ERR_MSG}}
  PYTHON_ALIAS=
  case "${PYTHON_VERSION}" in
    "2") PYTHON_ALIAS="py27" ;;
    "3") PYTHON_ALIAS="py36" ;;
    *) die "invalid python version ${PYTHON_VERSION}, either 2 or 3" ;;
  esac
}

parse_source_registry() {
  SOURCE_REGISTRY=
  for registry in ${DOCKER_REGISTRIES}; do
    if is_registry_available ${registry} ; then
      SOURCE_REGISTRY=${registry#*://}
      login_registry ${SOURCE_REGISTRY}
      break
    fi
  done
  [[ -n "${SOURCE_REGISTRY}" ]] || die "No available registry detected"
}

parse_target_idc() {
  TARGET_REGISTRY=
  case "${REGISTRY_IDC}" in
    "aws")  TARGET_REGISTRY=${AWS_REGISTRY} ;;
    "ppd") TARGET_REGISTRY=${PPD_REGISTRY} ;;
    *) echo "use no target idc"; return 0 ;;
  esac
  is_registry_available ${TARGET_REGISTRY} || die "${TARGET_REGISTRY} not available"
  login_registry ${TARGET_REGISTRY} || die "fail to login ${TARGET_REGISTRY}"
}

parse_task_type(){
  DOCKER_FILE=
  BUILDING_ARGS=
  RUNNING_MODE=
  RUNNING_OPTIONS=
  case "${TASK_TYPE}" in
    "service")
      DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.service"
      BUILDING_ARGS+=" --build-arg project_home_in_docker=${DOCKER_HOME}"
      BUILDING_ARGS+=" --build-arg project_name=${TASK_NAME}"
      CMD=
      RUNNING_MODE="-d --restart=unless-stopped"
      RUNNING_OPTIONS+=" --net=bridge -p ${SERVING_PORT:=18080}:8080"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR}"
      ;;
    "train")
      DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.train"
      BUILDING_ARGS+=" --build-arg project_home_in_docker=${DOCKER_HOME}"
      BUILDING_ARGS+=" --build-arg project_name=${TASK_NAME}"
      BUILDING_ARGS+=" --build-arg train_user=$(whoami) "
      BUILDING_ARGS+=" --build-arg train_uid=$(id -u)"
      BUILDING_ARGS+=" --build-arg train_gid=$(id -g)"
      RUNNING_MODE="-d"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR}"
      ;;
    "develop")
      DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
      BUILDING_ARGS+=" --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
      BUILDING_ARGS+=" --build-arg notebook_base_url=${TASK_NAME}"
      BUILDING_ARGS+=" --build-arg notebook_user=$(whoami)"
      BUILDING_ARGS+=" --build-arg notebook_uid=$(id -u)"
      BUILDING_ARGS+=" --build-arg notebook_gid=$(id -g)"
      CMD="start_notebook.sh"
      RUNNING_MODE="-d --restart=unless-stopped"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}:${PROJECT_HOME}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/data:${PROJECT_HOME}/data"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/log:${PROJECT_HOME}/log"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/models:${PROJECT_HOME}/models"
      RUNNING_OPTIONS+=" -w=\"${PROJECT_HOME}\""
      RUNNING_OPTIONS+=" -p ${NOTEBOOK_PORT:=18888}:8888"
      RUNNING_OPTIONS+=" -p ${SERVING_PORT:=18080}:8080"
      ;;
    "notebook")
      DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
      BUILDING_ARGS+=" --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
      BUILDING_ARGS+=" --build-arg notebook_base_url=${TASK_NAME}"
      BUILDING_ARGS+=" --build-arg notebook_user=$(whoami)"
      BUILDING_ARGS+=" --build-arg notebook_uid=$(id -u)"
      BUILDING_ARGS+=" --build-arg notebook_gid=$(id -g)"
      CMD="start_notebook.sh"
      RUNNING_MODE="-d --restart=unless-stopped"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/notebooks:/home/$(whoami)"
      RUNNING_OPTIONS+=" -p ${NOTEBOOK_PORT:=18888}:8888"
      ;;
    "debug")
      IMAGE_EXISTED="yes"
      CMD=
      RUNNING_MODE="-it"
      RUNNING_OPTIONS+=" --net=bridge -p ${SERVING_PORT:=18080}:8080"
      RUNNING_OPTIONS+=" --entrypoint /bin/bash"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/data:${DOCKER_DATA_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/log:${DOCKER_LOG_DIR}"
      RUNNING_OPTIONS+=" -v ${PROJECT_HOME}/models:${DOCKER_MODEL_DIR}"
      ;;
    *) die "unsupported task type: ${TASK_TYPE}" ;;
  esac
}

register() {
  [[ $# != 1 ]] && die "Usage, register registry"
  registered_tag=$1/${DOCKER_TAG}
  tag_cmd="${DOCKER} tag ${DOCKER_TAG} ${registered_tag}"
  push_cmd="${DOCKER} push ${registered_tag}"
  lazy_run "${tag_cmd} && ${push_cmd}"
}

use_registered() {
  [[ $# != 1 ]] && die "Usage, use_registered registry"
  pull_cmd="${DOCKER} pull $1/${DOCKER_TAG}"
  tag_cmd="${DOCKER} tag $1/${DOCKER_TAG} ${DOCKER_TAG}"
  lazy_run "${pull_cmd} && ${tag_cmd}"
}

prepare() {
  parse_device_type
  parse_python
  parse_source_registry
  parse_target_idc
  parse_task_type

  : ${OS_VERSION:?OS_VERSION ${EMPTY_ERR_MSG}}
  : ${DEEP_LEARNING_FRAMEWORK:?DEEP_LEARNING_FRAMEWORK ${EMPTY_ERR_MSG}}
  : ${DEEP_LEARNING_VERSION:?DEEP_LEARNING_VERSION ${EMPTY_ERR_MSG}}

  DOCKER_BASE="${SOURCE_REGISTRY}/${DEEP_LEARNING_FRAMEWORK}:${DEEP_LEARNING_VERSION}-${PYTHON_ALIAS}-${SYSTEM}-${OS_VERSION}"
  BUILDING_ARGS="--build-arg base=${DOCKER_BASE} ${BUILDING_ARGS}"
  BUILD_CMD="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${PROJECT_HOME}"
  RUN_CMD="${DOCKER_ENGINE} run ${RUNNING_MODE} --name ${TASK_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
}

build() {
  echo "building image ${DOCKER_TAG}"
  build_cmd="delete_image ${DOCKER_TAG} && ${BUILD_CMD}"
  lazy_run ${build_cmd}
  [[ -n "${TARGET_REGISTRY}" ]] && register ${TARGET_REGISTRY}
  echo "build ${DOCKER_TAG} successfully"
}

run() {
  echo "running image ${DOCKER_TAG} in ${TASK_TYPE} mode"
  [[ -n "${TARGET_REGISTRY}" ]] && use_registered ${TARGET_REGISTRY}
  run_cmd="delete_container ${TASK_NAME} && ${RUN_CMD} && is_container_running ${TASK_NAME}"
  lazy_run ${run_cmd}
  echo "run ${DOCKER_TAG} successfully"
}

