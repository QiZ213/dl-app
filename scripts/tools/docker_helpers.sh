#!/bin/bash
# Script to help build and run docker images

# docker settings
DOCKER=docker
DOCKER_HOME="/opt/${TASK_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"
DOCKER_NOTEBOOK_DIR="${DOCKER_HOME}/notebooks"

# docker registry settings
DOCKER_REGISTRIES=

# ppd docker registry settings
PPD_REGISTRY="dock.cbd.com:80"
PPD_REGISTRY_USER="admin"
PPD_REGISTRY_PASSWORD="admin123"
PPD_REGISTRY_LOGIN_CMD="${DOCKER} login -u ${PPD_REGISTRY_USER} -p ${PPD_REGISTRY_PASSWORD} ${PPD_REGISTRY}"
DOCKER_REGISTRIES+=" ${PPD_REGISTRY}"

# aws docker registry settings
AWS_REGISTRY="registry.ppdai.aws:5000"
DOCKER_REGISTRIES+=" ${AWS_REGISTRY}"

lazy_run() {
  if not_yes "${DRY_RUN}"; then
    eval "$@"
    die_if_err "fail to run: $@"
  fi
  blue_echo "done: $@"
}

check_settings() {
  local var=${!1}
  for i in $@; do
    local var=${!i}
    : ${var:? $i should not be empty, please check ${TARGET_COMMON_SETTINGS}}
  done
}

is_registry_available() {
  [[ $# != 1 ]] && die "Usage: is_registry_available docker_registry"
  mute curl --connect-timeout 1 --silent --insecure $1/v2/_catalog
}

login_registry() {
  [[ $# != 1 ]] && die "Usage: login_registry docker_registry"
  if [[ "$1" == "${PPD_REGISTRY}" ]];then
    mute eval "${PPD_REGISTRY_LOGIN_CMD}"
  fi
}

get_current_registry() {
  for registry in ${DOCKER_REGISTRIES}; do
    is_registry_available ${registry} && login_registry ${registry} && echo ${registry} && break
  done
}

is_image_existed() {
  [[ $# != 1 ]] && die "Usage: is_image_existed docker_image"
  mute ${DOCKER} image inspect $1
}

delete_image() {
  [[ $# != 1 ]] && die "Usage: delete_image docker_image"
  is_image_existed $1 && lazy_run ${DOCKER} rmi -f $1
}

is_container_existed() {
  [[ $# != 1 ]] && die "Usage: is_container_existed docker_container"
  mute ${DOCKER} container inspect $1
}

is_container_running() {
  [[ $# != 1 ]] && die "Usage: is_container_running docker_container"
  ${DOCKER} container inspect $1 | grep -q "\"Running\": true"
}

delete_container() {
  [[ $# != 1 ]] && die "Usage: delete_container docker_container"
  if is_container_existed $1; then
    lazy_run "${DOCKER} stop $1 && ${DOCKER} rm -v -f $1"
  fi
}

register() {
  [[ $# != 2 ]] && die "Usage, register docker_tag docker_registry"
  lazy_run "${DOCKER} tag $1 $2/$1 && ${DOCKER} push $2/$1"
}

use_registered() {
  [[ $# != 2 ]] && die "Usage, use_registered docker_tag docker_registry"
  lazy_run "${DOCKER} pull $2/$1 && ${DOCKER} tag $2/$1 $1"
}

parse_device_type(){
  case "${DEVICE_TYPE}" in
    "cpu")
      DOCKER_ENGINE="docker"
      SYSTEM="cpu"
      ;;
    "gpu")
      DOCKER_ENGINE="nvidia-docker"
      check_settings CUDA_VERSION CUDNN_VERSION
      SYSTEM="gpu-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}"
      ;;
    *) die "invalid device_type: $1, should be either cpu or gpu, please check cmd" ;;
  esac
}

parse_python_version() {
  case "${PYTHON_VERSION}" in
    "2") PYTHON_ALIAS="py27" ;;
    "3") PYTHON_ALIAS="py36" ;;
    *) die "invalid python version: $1, should be either 2 or 3, please check ${TARGET_COMMON_SETTINGS}" ;;
  esac
}

parse_registry_idc() {
  case "${REGISTRY_IDC}" in
    "aws") TARGET_REGISTRY=${AWS_REGISTRY} ;;
    "ppd") TARGET_REGISTRY=${PPD_REGISTRY} ;;
    *) echo "use no target idc"; return 0 ;;
  esac
  is_registry_available ${TARGET_REGISTRY} || die "${TARGET_REGISTRY} not available"
  login_registry ${TARGET_REGISTRY} || die "fail to login ${TARGET_REGISTRY}"
}

prepare(){
  parse_device_type
  parse_python_version
  parse_registry_idc

  SOURCE_REGISTRY=$(get_current_registry)

  check_settings OS_VERSION DEEP_LEARNING_FRAMEWORK DEEP_LEARNING_VERSION
  DOCKER_BASE="${DEEP_LEARNING_FRAMEWORK}:${DEEP_LEARNING_VERSION}-${PYTHON_ALIAS}-${SYSTEM}-${OS_VERSION}"
  [[ -n "${SOURCE_REGISTRY}" ]] && DOCKER_BASE="${SOURCE_REGISTRY}/${DOCKER_BASE}"

  [[ "${SOURCE_REGISTRY}" == "${PPD_REGISTRY}" ]] && IP=$(ip_address)
  : ${IP:=$(ip_address public)}

  # load task_type settings
  [[ -e ${TASK_TYPE_SETTINGS} ]] || die "unsupported task type: ${TASK_TYPE}, ${TASK_TYPE_SETTINGS} not existed"
  . ${TASK_TYPE_SETTINGS}
}

build() {
  echo "building image ${DOCKER_TAG}"
  delete_image ${DOCKER_TAG}
  lazy_run "${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${TARGET_HOME}"
  [[ -n "${TARGET_REGISTRY}" ]] && register ${DOCKER_TAG} ${TARGET_REGISTRY}
  echo "build ${DOCKER_TAG} successfully"
}

run() {
  echo "running image ${TASK_NAME}"
  [[ -n "${TARGET_REGISTRY}" ]] && use_registered ${DOCKER_TAG} ${SOURCE_REGISTRY}
  delete_container ${TASK_NAME}
  lazy_run "${DOCKER_ENGINE} run --name ${TASK_NAME} ${RUNNING_OPTS} ${DOCKER_TAG} ${CMD}"
  echo "run ${DOCKER_TAG} successfully"
}
