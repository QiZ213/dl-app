#!/bin/bash
# Script to launch the project by service|notebook|debug at local|remote
curr_dir=$(dirname $0)
. "${curr_dir}/common_settings.sh"  # import colors utils

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
  -v                 fill in TASK_VERSION, be used to Image Tag, default 0.1-whoami.
  -g                 fill in GIT_PATH, if code from gitlab, support only project component like "bird/dl-application"
  -b                 fill in GIT_BRANCH, default master
  -h                 fill in REMOTE_HOST, default run on local, or run on REMOTE_HOST by ssh
  --existed          Image Existed, run image without building image firstly. if ignore, no.
  --cpu              DEVICE_TYPE, if ignore, let DEVICE_TYPE be gpu.
  --overwrite        When remote run, would overwrite same files on remote host. if ignore, no.
  --clean            Clean task home firstly and assemble again. if ignore, no.
  --dry_run          Do not build docker image or run, but show docker command that are to be executed. if ignore, no.

[COMMAND]
USAGE
}

ip_address() {
  if [[ $1 == public ]]; then
    curl --silent http://ip.cn | awk '{print $2}' | sed 's/IP：//g'
  else
    # Do not support run by ssh on remote.
    ip addr | grep "inet\ " | grep -v docker0 | grep -v 127.0.0 | head -n 1 | awk '{print $2}' | sed 's/\/.*//'
  fi
}

if [[ $# -lt 2 ]]; then
  if [[ -n "$1" && $1 == --help ]]; then
    usage
    exit 0
  fi

  yellow_echo "Want to enter Interactive Mode? (y as enter, others as exit)"
  read -p "Interactive Mode (y/n)? " interactive_mode
  if ! is_yes "${interactive_mode}"; then
    exit 128
  else
    # Interactive Mode
    green_echo "=========== Welcome to Interactive Mode ==========="
    green_echo "Please ANSWER 3 QUESTIONS and type one of the options in [ ], or CTRL + C to exit."
    read -p "1.Which task do you want? [$(colorful service train notebook develop debug)] " TASK_TYPE
    read -p "2.Your project path? need absolute path. (if not exist currently, fill in your expected path): " TASK_HOME
    read -p "3.Which device_type do you choose? [$(colorful gpu cpu)] " DEVICE_TYPE
    if [[ ${TASK_TYPE} == train ]]; then
      read -p "Input your command in line: " CMD
      CMD=\"${CMD}\"
    fi

    if [[ "${DEVICE_TYPE}" == cpu ]]; then
      show_device_type="--cpu"
    else
      show_device_type=""
    fi

    echo "You could execute the command as follows instead of interactive mode."
    blue_echo "/bin/bash $0 ${TASK_TYPE} -t ${TASK_HOME} ${show_device_type} ${CMD}"
  fi
else
  TASK_TYPE=$1
  shift 1
  while [[ -n "$1" && "$1" =~ ^-.* ]]; do
    case "$1" in
      -t) TASK_HOME=$2 ;;
      -h) HOSTS=$2 ;;
      -g) GIT_PATH=$2 ;;
      -b) GIT_BRANCH=$2 ;;
      -s) SOURCE_PATH=$2 ;;
      -n) TASK_NAME=$2 ;;
      -r) REGISTRY_IDC=$2;;
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

DEFAULT_BASE_DIR=/opt
[[ -w ${DEFAULT_BASE_DIR} ]] || DEFAULT_BASE_DIR=~/opt

if [[ -n ${GIT_PATH} ]]; then
  [[ ${GIT_PATH} =~ (http|git@).* ]] || GIT_PATH="git@git.ppdaicorp.com:${GIT_PATH}"
  GIT_PATH=${GIT_PATH%.git}
  : ${GIT_BRANCH:=master}
  : ${TASK_VERSION:=${GIT_BRANCH}}
fi
: ${SOURCE_PATH:=${GIT_PATH}}

if [[ -z ${TASK_NAME} ]] ; then
  [[ -z ${SOURCE_PATH} ]] || : ${TASK_NAME:=$(basename ${SOURCE_PATH})}
  [[ -z ${TASK_HOME} ]] || : ${TASK_NAME:=$(basename ${TASK_HOME})}
  [[ -z ${TASK_NAME} ]] \
    && die "Cannot parse TASK_NAME, -t, -s, -g and -n must have one"
else
  [[ -z ${SOURCE_PATH} && -z ${TASK_HOME} ]] \
    && . ${curr_dir}/init.sh ${DEFAULT_BASE_DIR}/${TASK_NAME}
fi

: ${OVERWRITE:=no}
: ${TASK_HOME:=${DEFAULT_BASE_DIR}/${TASK_NAME}}
: ${IMAGE_EXISTED:=no}
: ${TASK_TYPE?"TASK_TYPE is required, but get null"}
: ${TASK_VERSION:=0.1-$(whoami)}
: ${DEVICE_TYPE:=gpu}
: ${REGISTRY_IDC:=local}
: ${DRY_RUN:=no}

access_tips() {
  case "${DOCKER_REGISTRY}" in
    dock\.cbd*) ip_addr=$(ip_address) ;;
    registry\.ppdai\.aws*) ip_addr=$(ip_address public) ;;
    *) ip_addr='start_the_service_IP';;
  esac

  case "${TASK_TYPE}" in
  notebook|develop)
    TIPS="Access notebook from"
    # Because source deploy_cmd, NOTEBOOK_PORT of the task has been loaded.
    URL=$(blue_echo "http://${ip_addr}:${NOTEBOOK_PORT}/${TASK_NAME}")
    echo "${TIPS} ${URL} Use default password"
    ;;
  service)
    TIPS1="Could the service be launched? Call"
    HELLO_URL=$(blue_echo "http://${ip_addr}:${SERVING_PORT}")  # same as NOTEBOOK_PORT
    echo -e "${TIPS1} ${HELLO_URL} and get $(green_echo Hello! Service is running)."

    TIPS2="Call your application from"
    API_URL=$(blue_echo "http://${ip_addr}:${SERVING_PORT}/service")
    echo -e "${TIPS2} ${API_URL}"
    ;;
  esac
  echo -e "Check running log by: $(green_echo docker logs -f ${TASK_NAME})"
}

clean_cmd="rm -rf ${TASK_HOME}"
is_yes "${CLEAN}" && ${clean_cmd}

assemble_cmd=". ${PROJECT_BIN}/tools/assemble.sh ${TASK_HOME} ${SOURCE_PATH} ${GIT_BRANCH}"
${assemble_cmd}

TASK_HOME=$(abs_dir_path ${TASK_HOME})
PROJECT_HOME=$(abs_dir_path ${PROJECT_HOME})
TASK_VERSION=${TASK_VERSION##*/}

deploy_cmd=". ${PROJECT_BIN}/tools/deploy.sh \
  ${TASK_HOME} \
  ${IMAGE_EXISTED} \
  ${TASK_NAME} \
  ${TASK_VERSION} \
  ${TASK_TYPE} \
  ${DEVICE_TYPE} \
  ${REGISTRY_IDC} \
  ${DRY_RUN} \
  ${CMD}"
if [[ -z ${HOSTS} ]]; then
  # run locally
  ${deploy_cmd} && access_tips
else
  # run remotely
  if not_yes "${OVERWRITE}"; then
    blue_echo "PLease check ${TASK_HOME} and ${PROJECT_HOME} on ${HOSTS}"
    blue_echo "Add --overwrite to overwrite them directly"
    exit 0
  fi
  HOSTS=${HOSTS//,/ }
  for host in ${HOSTS}; do
    ssh $(whoami)@${host} "mkdir -p ${TASK_HOME}"
    rsync -avz --progress -l ${TASK_HOME}/. $(whoami)@${host}:${TASK_HOME}
    ssh $(whoami)@${host} "mkdir -p ${PROJECT_HOME}"
    rsync -avz --progress -l ${PROJECT_HOME}/. $(whoami)@${host}:${PROJECT_HOME}
    ssh $(whoami)@${host} ${deploy_cmd}
  done
fi