#!/bin/bash
# Scripts to start cmd from RUN_USER
# It's inspired by : https://github.com/jupyter/docker-stacks/blob/master/base-notebook/start.sh

set -e

# Exec the specified command or fall back on bash
if [[ $# -eq 0 ]]; then
  cmd=bash
else
  cmd=$@
fi

update_user_info() {
  [[ $# == 3 ]] || exit 64
  user=$1
  uid=$2
  gid=$3
  if [[ -n "${uid}" && "$(id -u ${user})" != "${uid}" ]]; then
    sudo usermod -u ${uid} ${user}
  fi
  if [[ -n "${gid}" && "$(id -g ${user})" != "${gid}" ]]; then
    if grep "${user}:" /etc/group; then
      sudo groupmod -g ${gid} ${user}
    else
      sudo groupadd -g ${gid} ${user} && sudo usermod -g ${gid} ${user}
    fi
  fi
}

# Handle special flags if we're root
if [[ $(id -u) == 0 ]]; then

  # Switch to RUN_USER if RUN_USER is defined
  if [[ -n "${RUN_USER}" ]]; then
    ! id ${RUN_USER} &> /dev/null && useradd -m -s /bin/bash -N ${RUN_USER}
    update_user_info "${RUN_USER}" "${RUN_UID}" "${RUN_GID}"

    echo "Executing the command by ${RUN_USER}: ${cmd}"
    exec sudo -E -H -u ${RUN_USER} env \
      PATH=${PATH} \
      PYTHONPATH=${PYTHONPATH:-} \
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-} \
      LD_PRELOAD=${LD_PRELOAD:-} \
      ${cmd}
  else
    echo "Executing the command by root: ${cmd}"
    exec ${cmd}
  fi

# Handle special flags if we're not root
else
  # Grant group permission if RUN_UID is different from current user
  if [[ -n "${RUN_UID}" && "$(id -u)" != "${RUN_UID}" ]]; then
    if sudo -n true; then
      sudo find -L "/home/${RUN_USER}" \
        \( -perm /u+w -a ! -perm /g+w -a ! -path "*/\.*" \) \
        -exec chmod g+w {} \;
    else
      echo "Current user has no sudo privilege to switch user"
    fi
  fi
  exec ${cmd}
fi
