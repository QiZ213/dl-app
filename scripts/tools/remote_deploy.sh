#! /bin/bash
# Scripts to deploy project at remote.
if [[ $# -ne 2 ]]; then
  echo "Illegal arguments: ./remote_deploy.sh remote_ip task_type"
  echo "e.g. $ /bin/bash ./remote_deploy.sh 255.255.255.0 notebook"
  exit 128
fi
. "${BASH_SOURCE%/*}/../common_settings.sh"

set -e

REMOTE_IP=$1
TASK_TYPE=$2
REMOTE_USER=$(whoami)


ssh_exec() {
  if [ $# -lt 1 ]; then
    echo "Illegal arguments. CMD is necessary."
    return 64
  fi

  ssh ${REMOTE_USER}@${REMOTE_IP} "$@"

}

absolute_path() {
  path=$1
  echo "$(cd ${path} && pwd)"
}

rsync_folder() {
  local=$(absolute_path $1)
  remote=$(absolute_path $2)

  rsync -avz --progress ${local} ${REMOTE_USER}@${REMOTE_IP}:${remote}
}

check_remote_file_exist() {
  remote=$(absolute_path $1)
  ssh_exec "[ -e ${remote} ]"
}

check_port_listen() {
  port=$1
  is_remote=$2

  port_pattern=":${port} "
  if [ -z ${is_remote} ]; then
    netstat -ln | grep ${port_pattern}
  else
    ssh_exec "netstat -ln | grep ${port_pattern}"
  fi
}

rsync_part_of_project() {
  folder_path=$1
  target_tag=$2

  if [[ $# -ne 2 ]];then
    echo "Illegal arguments: need folder_path local_tag"
    echo "e.g. transfer_folder ${PROJECT_HOME}/data data"
    exit 64
  fi

  target_path=${PROJECT_HOME}/${target_tag}

  if [[ $(absolute_path ${target_path}) != $(absolute_path ${folder_path}) ]]; then
    rsync_folder ${folder_path} $(dirname $(absolute_path ${folder_path}))
  fi
}

# check if network port listened,
# remote port need not to be occupied.
case ${TASK_TYPE} in
  notebook)
    check_port_listen ${NOTEBOOK_PORT} is_remote && {
      red_echo "Error: remote port for notebook: ${NOTEBOOK_PORT} is listened" \
      && red_echo "  Please check it and replace another one in scripts/common_setting.sh" \
      && exit 128
    } ;;
  service)
    check_port_listen ${SERVING_PORT} is_remote && {
      red_echo "Error: remote port for service: ${SERVING_PORT} is listened" \
      && red_echo "  Please check it and replace another one in scripts/common_setting.sh" \
      && exit 128
    } ;;
  *)
    :
    ;;
esac


# check if transfer folder exist in remote,
# remote path need not to exist.
for transfer_path in ${PROJECT_HOME} ${DATA_DIR} ${LOG_DIR} ${NOTEBOOK_DIR}; do

  if check_remote_file_exist ${transfer_path}; then
    echo "${transfer_path} exist it will synchronize files by rsync."
    read -p "Continue or Stop [y|n]? " go_on
    if echo "${go_on}" | grep -q "^[Yy]\([Ee][Ss]\)*$" ; then
      continue
    else
      echo -e "Error: remote files existed, and you do not choose to synchronize."
      exit 128
    fi
  fi
done


# transfer files to remote with origin sort links
rsync_part_of_project ${NOTEBOOK_DIR} notebooks \
  && rsync_part_of_project ${DATA_DIR} data \
  && rsync_part_of_project ${LOG_DIR} log \
  && rsync_folder ${PROJECT_HOME} $(dirname $(absolute_path ${PROJECT_HOME}))

