#!/bin/bash
# Scripts to start cmd from USER
# It's inspired by : https://github.com/jupyter/docker-stacks/blob/master/base-notebook/start.sh

set -e

# Exec the specified command or fall back on bash
if [[ $# -eq 0 ]]; then
  cmd=bash
else
  cmd=$@
fi

# Handle special flags if we're root
if [[ $(id -u) == 0 ]]; then

  # Switch to USER if USER is defined
  if [[ ! -z "${USER}" ]] && ! mute id ${USER} ; then
    : ${UID:=1000}
    : ${GID:=100}
    groupadd -f -g ${GID} ${USER}
    useradd -m -s /bin/bash -N -u ${UID} -g ${GID} ${USER}
    chown -R ${USER}:${GID} ${HOME}
    usermod -a -G root ${USER}
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" | mute tee -a /etc/sudoers.d/notebook

    echo "Executing the command: ${cmd}"
    exec sudo -E -H -u ${USER} PATH=${PATH} ${cmd}
  else
    echo "Executing the command: ${cmd}"
    exec ${cmd}
  fi

# Check special flags if we're not root
else
  if [[ ! -z "${UID}" && "${UID}" != "$(id -u)" ]]; then
    echo "Container must be run as root to set ${UID}"
  fi
  if [[ ! -z "${GID}" && "${GID}" != "$(id -g)" ]]; then
    echo "Container must be run as root to set ${GID}"
  fi

  echo "Executing the command: ${cmd}"
  exec ${cmd}
fi
