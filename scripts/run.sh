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


if [[ $# -lt 5 ]]; then
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
  PROJECT_NAME=$2
  TASK_TYPE=$3
  shift 3
  while [[ -n "$1" ]]; do
    case "$1" in
      -v) PROJECT_VERSION=$2;;
      -h) HOST=$2;;
      --cpu) DEVICE_TYPE="cpu";;
      --existed) IMAGE_EXISTED="yes";;
      --dry_run) DRY_RUN="yes";;
      --help) usage; exit 128;;
      *) die "unsupported arguments $1"
    esac
    [[ "$1" =~ ^--.* ]] || shift 1
    shift 1
  done
fi

# required parameters
: ${IDC_NAME?"IDC_NAME is required, but get null"}
: ${PROJECT_NAME?"PROJECT_NAME is required, but get null"}
: ${TASK_TYPE?"TASK_TYPE is required, but get null"}

# overwritten parameters
: ${DEVICE_TYPE:=gpu}
: ${PROJECT_VERSION:=0.1}

. "${CURR_DIR}/tools/assemble.sh" ${PROJECT_NAME}
. "${CURR_DIR}/tools/deploy.sh" ${IDC_NAME} ${DEVICE_TYPE} ${PROJECT_NAME} ${PROJECT_VERSION} ${TASK_TYPE}