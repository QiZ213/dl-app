#!/bin/bash

curr_dir=$(cd $(dirname ${BASH_SOURCE}); pwd)

source_existed() {
  if [[ -e $1 ]]; then
    . $1
  fi
}

install_base_required() {
  apt-get install -yq --no-install-recommends \
    libglib2.0-0 \
  && pip install --no-cache-dir opencv-python==3.3.0.9
}


# install os requirements
apt-get update \
&& install_base_required \
&& source_existed ${curr_dir}/install_custom.sh \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
