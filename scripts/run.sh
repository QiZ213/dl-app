#!/bin/bash
# Script to launch the project by service|notebook|debug at local|remote
curr_dir=$(dirname ${BASH_SOURCE[0]})
. "${curr_dir}/common_settings.sh"

usage() {
  cat << USAGE >&2
USAGE:
  /bin/bash run.sh TASK_TYPE TASK_HOME [OPTIONS] [COMMAND]
  e.g
  /bin/bash run.sh notebook -s ~/awesome_project
  /bin/bash run.sh train -s ~/awesome_project "python main.py"
  /bin/bash run.sh service -s ~/awesome_project --existed

ARGUMENTS
  TASK_TYPE          Task type supported: service,train,notebook,develop,debug,init
[OPTIONS]
  -t                 fill in TASK_HOME (if not exists currently, fill in your expected path;
                       if exists, structure of TASK_HOME must meet requirements of dl-application. See documents).
  -s                 fill in SOURCE_PATH, user project home, "scripts/common-settings.sh" is required in SOURCE_PATH.
  -n                 fill in TASK_NAME, be used to Image Tag, Container Name, default basename of task_home.
  -g                 fill in GIT_PATH, if code from gitlab, support only project component like "bird/dl-application"
  -b                 fill in GIT_BRANCH or GIT_TAG, default master
  -dt                fill in DOCKER_TAG, docker image tag, default "TASK_NAME:TASK_VERSION"
  -h                 fill in REMOTE_HOST, default run on local, or run on REMOTE_HOST by ssh
  -v                 fill in TASK_VERSION, default 0.1-whoami
  -gpu               file in NV_GPU, GPU isolation, same as CUDA_VISIBLE_DEVICES
  --existed          Image Existed, run image without building image firstly. if ignore, no.
  --cpu              DEVICE_TYPE, if ignore, let DEVICE_TYPE be gpu.
  --overwrite        When remote run, would overwrite same files on remote host. if ignore, no.
  --clean            Clean task home firstly and assemble again. if ignore, no.
  --dry_run          Do not build docker image or run, but show docker command that are to be executed. if ignore, no.

[COMMAND]
USAGE
}

if [[ $# -lt 2 ]]; then
  if [[ -n "$1" && $1 == --help ]]; then
    usage
    exit 0
  fi
else
  TASK_TYPE=$1
  shift 1
  while [[ -n "$1" && "$1" =~ ^-.* ]]; do
    case "$1" in
      -t) TARGET_PATH=$2 ;;
      -h) HOSTS=$2 ;;
      -g) GIT_PATH=$2 ;;
      -b) GIT_BRANCH=$2 ;;
      -s) SOURCE_PATH=$2 ;;
      -n) TASK_NAME=$2 ;;
      -r) REGISTRY_IDC=$2 ;;
      -v) TASK_VERSION=$2 ;;
      -dt) DOCKER_TAG=$2 ;;
      -gpu) NV_GPU=$2 ;;
      --cpu) DEVICE_TYPE="cpu" ;;
      --existed) IMAGE_EXISTED="yes" ;;
      --dry_run) DRY_RUN="yes" ;;
      --clean) CLEAN="yes" ;;
      --overwrite) OVERWRITE="yes";;
      *) die "unsupported arguments $1, check usage by \"/bin/bash $0 --help\""
    esac
    [[ "$1" =~ ^--.* ]] || shift 1
    shift 1
  done
  CMD=\"$@\"
fi

# parse global parameters
DEFAULT_BASE_DIR="$(get_default_base_dir)"

# parse task_name
[[ -n ${SOURCE_PATH} ]] && : ${TASK_NAME:=$(basename ${SOURCE_PATH})}
[[ -n ${GIT_PATH} ]] && : ${TASK_NAME:=$(basename ${GIT_PATH} ".git")}
: ${TASK_NAME? "cannot parse TASK_NAME, -s, -g and -n must have one"}

# parse task_version
: ${TASK_VERSION:=${GIT_BRANCH##*/}}
: ${TASK_VERSION:="test-$(whoami)"}

# parse required parameters
: ${CLEAN:="no"}
: ${OVERWRITE:="no"}
: ${TARGET_PATH:=${DEFAULT_BASE_DIR}/${TASK_NAME}}
: ${IMAGE_EXISTED:="no"}
: ${DEVICE_TYPE:="gpu"}
: ${REGISTRY_IDC:="local"}
: ${DRY_RUN:="no"}
: ${DOCKER_TAG:=${TASK_NAME}:${TASK_VERSION}}

# init source project
if [[ -z ${SOURCE_PATH} ]]; then
  [[ -n ${GIT_PATH} ]] && SOURCE_PATH=${DEFAULT_BASE_DIR}/tmp/$(basename ${GIT_PATH} ".git")
  : ${SOURCE_PATH:=${DEFAULT_BASE_DIR}/tmp/${TASK_NAME}}
  trap "rm -rf ${SOURCE_PATH}" EXIT
fi
if [[ ! -d ${SOURCE_PATH} ]]; then
  mkdir -p ${SOURCE_PATH}
  die_if_err "${SOURCE_PATH} should be a directory if existed"
  if [[ -n ${GIT_PATH} ]]; then
    [[ ${GIT_PATH} =~ (http|git@).* ]] || GIT_PATH="git@git.ppdaicorp.com:${GIT_PATH}"
    : ${GIT_BRANCH:=master}
  fi
  git clone --recursive --depth=1 ${GIT_PATH} -b ${GIT_BRANCH} ${SOURCE_PATH}
fi
SOURCE_NAME=$(basename ${SOURCE_PATH})
echo ${SOURCE_PATH}
echo ${SOURCE_NAME}
if [[ -d ${SOURCE_PATH}/${SOURCE_NAME} ]]; then
  MODULE_NAME=${SOURCE_NAME}
else
  MODULE_NAME=${TASK_NAME}
fi

clean_cmd="rm -rf ${TARGET_PATH}"
is_yes "${CLEAN}" && ${clean_cmd}

assemble_cmd=". ${PROJECT_BIN}/tools/assemble.sh ${SOURCE_PATH} ${TARGET_PATH}"
${assemble_cmd}

TARGET_PATH=$(abs_dir_path ${TARGET_PATH})

deploy_cmd=". ${PROJECT_BIN}/tools/deploy.sh \
  ${TARGET_PATH} \
  ${TASK_NAME} \
  ${TASK_TYPE} \
  ${MODULE_NAME} \
  ${DOCKER_TAG} \
  ${DEVICE_TYPE} \
  ${REGISTRY_IDC} \
  ${IMAGE_EXISTED} \
  ${DRY_RUN} \
  ${CMD}"

if [[ -z ${HOSTS} ]]; then
  # run locally
  NV_GPU=${NV_GPU} ${deploy_cmd} && echo -e ${TIPS}
else
  # run remotely
  if not_yes "${OVERWRITE}"; then
    blue_echo "PLease check ${TARGET_PATH} and ${PROJECT_HOME} on ${HOSTS}"
    blue_echo "Add --overwrite to overwrite them directly"
    exit 0
  fi
  HOSTS=${HOSTS//,/ }
  for host in ${HOSTS}; do
    ssh $(whoami)@${host} "mkdir -p ${PROJECT_HOME}"
    rsync -avz --progress -l ${PROJECT_HOME}/. $(whoami)@${host}:${PROJECT_HOME}
    ssh $(whoami)@${host} "mkdir -p ${TARGET_PATH}"
    rsync -avz --progress -l ${TARGET_PATH}/. $(whoami)@${host}:${TARGET_PATH}
    ssh $(whoami)@${host} NV_GPU=${NV_GPU} ${deploy_cmd}
  done
fi
