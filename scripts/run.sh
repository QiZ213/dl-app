#!/bin/bash
# Script to launch the project by service|notebook|debug at local|remote
CURR_DIR=$(dirname $0)
. "${CURR_DIR}/common_settings.sh"  # import colors utils

usage() {
  cat << USAGE >&2
  Usage:
    /bin/bash run.sh idc_name device_type project_name version task_type --exist -h remote_ip
  e.g 1: /bin/bash run.sh ppd gpu awesome_name 0.1 notebook
  e.g 2: /bin/bash run.sh ppd gpu awesome_name 0.2 service --exist
  e.g 3: /bin/bash run.sh ppd gpu awesome_name 0.1 service 172.1.3.0
  e.g 4: /bin/bash run.sh ---------> Enter, and Type "y" to Interactive Mode.
  ARGUMENTS      OPTION                         DESCRIPTION
  idc_name       ppd | aws                      Where is the project code
  device_type    cpu | gpu                      Which device_type you choose
  project_name   Manually Input                 Project name & Image name
  version        Manually Input                 Project version & Image Tag
  task_type      service|notebook|train|debug   Which task to build and run
  --exist        ------                         (Optional) Image Existed, run image without building image firstly
                                                           If ignored, build image first and run image.
  -h             Manually Input                 (Optional) Run on the Remote_ip, default run on local
                                                           If ignored, run on local.
USAGE
}


if [[ $# -lt 3 ]]; then
  usage
  yellow_echo "Want to enter Interactive Mode? (y as enter, others as exit)"
  read -p "Interactive Mode (y/n)? " interactive_mode
  if ! is_yes "${interactive_mode}"; then
    exit 128
  else
    # Interactive Mode
    green_echo "=========== Welcome to Interactive Mode ==========="
    green_echo "Please ANSWER 7 QUESTIONS and type one of the options in [ ], or CTRL + C to exit."
    read -p "1.Where is the project code? [$(colorful aws ppd)] " IDC_NAME
    read -p "2.Which device_type do you choose? [$(colorful gpu cpu)] " DEVICE_TYPE
    read -p "3.Project name? PLEASE INPUT: " PROJECT_NAME
    read -p "4.Project version? default $(colorful 0.1), PLEASE INPUT: " PROJECT_VERSION
    read -p "5.Which task do you want? [$(colorful service train notebook debug)] " TASK_TYPE
    read -p "6.Image existed? default no. [$(colorful yes no)] " IMAGE_EXISTED
    read -p "7.Remote Run? INPUT remote ip, or ENTER to run at local. " REMOTE_IP
  fi
else
  IDC_NAME=$1
  TASK_HOME=$2
  TASK_TYPE=$3
  shift 3
  while [[ -n "$1" ]]; do
    case "$1" in
      -v) PROJECT_VERSION=$2 ;;
      -h) HOST=$2 ;;
      -g) GIT_PATH=$2 ;;
      -b) GIT_BRANCH=$2 ;;
      -s) SOURCE_PATH=$2 ;;
      -n) TASK_NAME=$2 ;;
      -t) USER_PROJECT_HOME=$2 ;;
      --cpu) DEVICE_TYPE="cpu" ;;
      --existed) IMAGE_EXISTED="yes" ;;
      --dry_run) DRY_RUN="yes" ;;
      --overwrite) OVERWRITE="yes";;
      --help) usage; exit 128 ;;
      *) die "unsupported arguments $1"
    esac
    [[ "$1" =~ ^--.* ]] || shift 1
    shift 1
  done
fi

current_bin=${PROJECT_BIN}
current_home=${PROJECT_HOME}
current_user=$(whoami)

: ${IDC_NAME?"IDC_NAME is required, but get null"}
: ${TASK_HOME?"TASK_HOME is required, but get null"}
: ${TASK_TYPE?"TASK_TYPE is required, but get null"}

: ${DEVICE_TYPE:=gpu}
: ${DRY_RUN:=no}
: ${IMAGE_EXISTED:=no}
: ${OVERWRITE:=no}
: ${TASK_NAME:=$(basename ${TASK_HOME})}
: ${TASK_VERSION:=0.1-$(whoami)}

[[ ${GIT_PATH} =~ git@.* ]] || GIT_PATH="git@git.ppdaicorp.com:$(whoami)/${GIT_PATH}"
[[ -z ${GIT_PATH} ]] || GIT_BRANCH=${GIT_BRANCH:=master}
SOURCE_PATH=${SOURCE_PATH:=${GIT_PATH}}

clean_cmd="rm -rf ${TASK_HOME}"
assemble_cmd=". ${current_bin}/tools/assemble.sh ${TASK_HOME} ${SOURCE_PATH} ${GIT_BRANCH}"
deploy_cmd=". ${current_bin}/tools/deploy.sh \
  ${TASK_HOME} ${IDC_NAME} ${DEVICE_TYPE} ${TASK_NAME} ${TASK_VERSION} ${TASK_TYPE} ${IMAGE_EXISTED} ${DRY_RUN}"

# assemble
is_yes "${IMAGE_EXISTED}" || ${clean_cmd}
${assemble_cmd}

# deploy
if [[ -z ${HOST} ]]; then
  ${deploy_cmd}
else
  if is_yes "${OVERWRITE}"; then
    TASK_HOME=$(absolute_path ${TASK_HOME})
    rsync -avz --progress ${TASK_HOME}/. ${current_user}@${HOST}:${TASK_HOME}
    rsync -avz --progress ${current_home}/. ${current_user}@${HOST}:${current_home}
  else
    blue_echo "Please check ${current_home} on ${HOST}"
    blue_echo "Add --overwrite in your run cmd to overwrite it directly"
    exit 0
  fi
  ssh ${current_user}@${HOST} ${deploy_cmd}
fi