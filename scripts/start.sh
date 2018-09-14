#!/bin/bash
# Scripts to start cmd from user defined in USER.
# It's inspired by : https://github.com/jupyter/docker-stacks/blob/master/base-notebook/start.sh

set -e
: ${DEFAULT_USER:=cbd}

curr_dir=$(dirname $0)
. ${curr_dir}/common_settings.sh

# Exec the specified command or fall back on bash
if [[ $# -eq 0 ]]; then
  cmd=bash
else
  cmd=$@
fi

# Handle special flags if we're root
if [[ $(id -u) == 0 ]]; then

  # changing user if USER is set and it's not DEFAULT_USER
  if [[ ! -z "${USER}" && "${USER}" != "${DEFAULT_USER}" ]]; then

    # Only attempt to change the default username if it exists
    if id ${DEFAULT_USER} &> /dev/null; then
      echo "set user to: ${USER}"
      usermod -d /home/${USER} -l ${USER} ${DEFAULT_USER}
    else
      useradd -d /home/${USER} -M ${USER}
    fi

    # changing username, make sure home_dir exists
    # (it could be mounted, and we shouldn't create it if it already exists)
    if [[ ! -e "/home/${USER}" ]]; then
      echo "relocate home dir to /home/${USER}"
      test -d /home/${DEFAULT_USER}  && mv /home/${DEFAULT_USER} "/home/${USER}" \
        || mkdir /home/${USER}
    fi

    # changing working directory
    if [[ "${PWD}/" == "/home/${DEFAULT_USER}/"* ]]; then
      new_cwd=${PWD/${DEFAULT_USER}/${USER}}
      echo "set CWD to ${new_cwd}"
      cd "${new_cwd}"
    fi

    # changing uid of USER to UID if it does not match
    if [[ ! -z "${UID}" && "${UID}" != $(id -u ${USER}) ]]; then
      echo "set uid of ${USER} to: ${UID}"
      usermod -u ${UID} ${USER}
    fi

    # changing gid of USER to GID if it does not match
    if [[ ! -z "${GID}" && "${GID}" != $(id -g ${USER}) ]]; then
      echo "set gid of ${USER} to: ${GID}"
      groupmod -g ${GID} -o $(id -g -n ${USER})
    fi

    chown -R ${USER} /home/${USER}

    echo "${USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/${USER} &> /dev/null
  fi

  # Exec the command as USER with the PATH and the rest of the environment preserved
  echo "Executing the command: ${cmd}"
  exec sudo -E -H -u ${USER} PATH=${PATH} ${cmd}

# Check special flags if we're not root
else
  if [[ ! -z "${UID}" && "${UID}" != "$(id -u)" ]]; then
    echo "Container must be run as root to set ${UID}"
  fi
  if [[ ! -z "${GID}" && "${GID}" != "$(id -g)" ]]; then
    echo "Container must be run as root to set ${GID}"
  fi

  # Execute the command
  echo "Executing the command: ${cmd}"
  exec ${cmd}
fi
