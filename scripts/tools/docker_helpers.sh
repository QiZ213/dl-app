#!/bin/bash
# Script to help build and run docker images

# err msg settings
EMPTY_SETTING_ERR="should not be empty, check ${TARGET_HOME}/scripts/common_settings.sh"

# docker settings
DOCKER=docker
DOCKER_HOME="/opt/${TASK_NAME}"
DOCKER_DATA_DIR="${DOCKER_HOME}/data"
DOCKER_LOG_DIR="${DOCKER_HOME}/log"
DOCKER_MODEL_DIR="${DOCKER_HOME}/models"
DOCKER_NOTEBOOK_DIR="${DOCKER_HOME}/notebooks"
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
    eval $@
    die_if_err "fail to run: $@"
  fi
  blue_echo "done: $@"
}

is_registry_available() {
  [[ $# != 1 ]] && die "Usage: is_registry_available docker_registry"
  mute curl --connect-timeout 1 --silent --insecure $1/v2/_catalog
}

login_registry() {
  [[ $# != 1 ]] && die "Usage: login_registry docker_registry"
  if [[ "$1" == "${PPD_REGISTRY}" ]];then
    mute eval ${PPD_REGISTRY_LOGIN_CMD}
  fi
}

is_image_existed() {
  [[ $# != 1 ]] && die "Usage: is_image_existed docker_image"
  mute ${DOCKER} image inspect "$1"
}

delete_image() {
  [[ $# != 1 ]] && die "Usage: delete_image docker_image"
  if is_image_existed "$1"; then
    lazy_run "${DOCKER} rmi -f $1"
  fi
}

is_container_existed() {
  [[ $# != 1 ]] && die "Usage: is_container_existed docker_container"
  mute ${DOCKER} container inspect "$1"
}

is_container_running() {
  [[ $# != 1 ]] && die "Usage: is_container_running docker_container"
  ${DOCKER} container inspect "$1" | grep -q "\"Running\": true"
}

delete_container() {
  [[ $# != 1 ]] && die "Usage: delete_container docker_container"
  if is_container_existed "$1"; then
    lazy_run "${DOCKER} stop $1 && ${DOCKER} rm -v -f $1"
  fi
}

parse_device_type(){
  DOCKER_ENGINE=
  SYSTEM=

  case "${DEVICE_TYPE}" in
    "cpu")
      DOCKER_ENGINE="docker"
      SYSTEM="cpu"
      ;;
    "gpu")
      DOCKER_ENGINE="${NV_GPU} nvidia-docker"
      : ${CUDA_VERSION:?CUDA_VERSION ${EMPTY_SETTING_ERR}}
      : ${CUDNN_VERSION:?CUDNN_VERSION ${EMPTY_SETTING_ERR}}
      SYSTEM="gpu-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}"
      ;;
    *) die "invalid device_type ${DEVICE_TYPE}, either cpu or gpu" ;;
  esac
}

parse_python() {
  PYTHON_ALIAS=

  : ${PYTHON_VERSION:?PYTHON_VERSION ${EMPTY_SETTING_ERR}}
  case "${PYTHON_VERSION}" in
    "2") PYTHON_ALIAS="py27" ;;
    "3") PYTHON_ALIAS="py36" ;;
    *) die "invalid python version ${PYTHON_VERSION}, either 2 or 3" ;;
  esac
}

parse_source_registry() {
  SOURCE_REGISTRY=
  IP=

  for registry in ${DOCKER_REGISTRIES}; do
    if is_registry_available ${registry} ; then
      SOURCE_REGISTRY=${registry#*://}
      login_registry ${SOURCE_REGISTRY}
      break
    fi
  done
  [[ -n "${SOURCE_REGISTRY}" ]] || die "No available registry detected"
  if [[ "${SOURCE_REGISTRY}" == "${PPD_REGISTRY}" ]]; then
    IP=$(ip_address)
  else
    IP=$(ip_address public)
  fi
}

parse_target_idc() {
  TARGET_REGISTRY=

  case "${REGISTRY_IDC}" in
    "aws") TARGET_REGISTRY=${AWS_REGISTRY} ;;
    "ppd") TARGET_REGISTRY=${PPD_REGISTRY} ;;
    *) echo "use no target idc"; return 0 ;;
  esac
  is_registry_available ${TARGET_REGISTRY} || die "${TARGET_REGISTRY} not available"
  login_registry ${TARGET_REGISTRY} || die "fail to login ${TARGET_REGISTRY}"
}

parse_task_type() {
  DOCKER_FILE=
  BUILDING_ARGS=
  RUNNING_MODE=
  RUNNING_OPTS=

  # default docker base
  : ${OS_VERSION:?OS_VERSION ${EMPTY_SETTING_ERR}}
  : ${DEEP_LEARNING_FRAMEWORK:?DEEP_LEARNING_FRAMEWORK ${EMPTY_SETTING_ERR}}
  : ${DEEP_LEARNING_VERSION:?DEEP_LEARNING_VERSION ${EMPTY_SETTING_ERR}}
  DOCKER_BASE_VERSION="${DEEP_LEARNING_VERSION}-${PYTHON_ALIAS}-${SYSTEM}-${OS_VERSION}"
  DOCKER_BASE="${SOURCE_REGISTRY}/${DEEP_LEARNING_FRAMEWORK}:${DOCKER_BASE_VERSION}"

  # load task_type settings
  TASK_TYPE_SETTINGS="${PROJECT_BIN}/tools/task_types/${TASK_TYPE}.sh"
  [[ -e ${TASK_TYPE_SETTINGS} ]] || die "unsupported task type: ${TASK_TYPE}, ${TASK_TYPE_SETTINGS} not existed"
  . ${TASK_TYPE_SETTINGS}
}

register() {
  [[ $# != 1 ]] && die "Usage, register docker_registry"
  registered_tag=$1/${DOCKER_TAG}
  tag_cmd="${DOCKER} tag ${DOCKER_TAG} ${registered_tag}"
  push_cmd="${DOCKER} push ${registered_tag}"
  lazy_run "${tag_cmd} && ${push_cmd}"
}

use_registered() {
  [[ $# != 1 ]] && die "Usage, use_registered docker_registry"
  pull_cmd="${DOCKER} pull $1/${DOCKER_TAG}"
  tag_cmd="${DOCKER} tag $1/${DOCKER_TAG} ${DOCKER_TAG}"
  lazy_run "${pull_cmd} && ${tag_cmd}"
}

prepare() {
  # parse args
  parse_device_type
  parse_python
  parse_source_registry
  parse_target_idc
  parse_task_type
}

build() {
  build_cmd="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${TARGET_HOME}"

  echo "building image ${DOCKER_TAG}"
  delete_image ${DOCKER_TAG}
  lazy_run ${build_cmd}
  [[ -n "${TARGET_REGISTRY}" ]] && register ${TARGET_REGISTRY}
  echo "build ${DOCKER_TAG} successfully"
}

run() {
  run_cmd="${DOCKER_ENGINE} run ${RUNNING_MODE} --name ${TASK_NAME} ${RUNNING_OPTS} ${DOCKER_TAG} ${CMD}"
  echo "running image ${TASK_NAME}"
  [[ -n "${TARGET_REGISTRY}" ]] && use_registered ${TARGET_REGISTRY}
  delete_container ${TASK_NAME}
  lazy_run ${run_cmd}
  echo "run ${DOCKER_TAG} successfully"
}

