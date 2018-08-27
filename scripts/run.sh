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
  DEVICE_TYPE=$2
  PROJECT_NAME=$3
  PROJECT_VERSION=$4
  TASK_TYPE=$5
fi




while [ $# -gt 5 ]; do
  case "$6" in
    --exist)
      IMAGE_EXISTED="yes"
      shift 1
      ;;
    -h)
      REMOTE_IP=$7
      shift 2
      ;;
    --help)
      usage
      exit 1
      ;;
    *)
      red_echo "Illegal arguments: $6"
      usage
      exit 1
      ;;
  esac
done


# arguments validate
if [ -z "${PROJECT_NAME}" ]; then
  red_echo "PROJECT_NAME is necessary, but get null"
  exit 128
fi

PROJECT_VERSION=${PROJECT_VERSION:=0.1}

# deploy. if not remote_ip, build soft link at local; else rsync files to remote.
if [ -z "${REMOTE_IP}" ]; then
  . "${CURR_DIR}/tools/local_deploy.sh" ${PROJECT_NAME} ${TASK_TYPE}
  EXEC="."
else
  . "${CURR_DIR}/tools/remote_deploy.sh" ${REMOTE_IP} ${TASK_TYPE}
  EXEC="ssh_exec /bin/bash"
fi


# run the task.
echo "${EXEC} ${PROJECT_HOME}/scripts/tools/launch.sh ${IDC_NAME} ${DEVICE_TYPE} ${PROJECT_NAME} ${PROJECT_VERSION} ${TASK_TYPE} ${IMAGE_EXISTED}"
eval "${EXEC} ${PROJECT_HOME}/scripts/tools/launch.sh ${IDC_NAME} ${DEVICE_TYPE} ${PROJECT_NAME} ${PROJECT_VERSION} ${TASK_TYPE} ${IMAGE_EXISTED}"