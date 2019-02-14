#!/bin/bash

curr_dir=$(cd $(dirname ${BASH_SOURCE}); pwd)

source_existed() {
  if [[ -e $1 ]]; then
    . $1
  fi
}

pip_install() {
  if [[ -n ${PYPI} ]]; then
    pip install --no-cache-dir -i ${PYPI} $@
  else
    pip install --no-cache-dir $@
  fi
}

apt_install() {
  apt-get install -yq --no-install-recommends $@
}

install_base_required() {
  apt_install libglib2.0-0
  pip_install opencv-python==3.3.0.9
}


# install os requirements
apt-get update \
  && install_base_required \
  && source_existed ${curr_dir}/install_custom.sh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
