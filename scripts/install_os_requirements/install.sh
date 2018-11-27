#!/bin/bash

source_existed() {
  if [[ -e $1 ]]; then
    . $1
  fi
}

install_base_required() {
  apt-get install -yq --no-install-recommends \
    libglib2.0-0
}


# install os requirements
apt-get update \
&& install_base_required \
&& source_existed ./custom_requirements.sh \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
