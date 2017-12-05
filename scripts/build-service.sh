#!/bin/bash
if [ $# -lt 3 ]; then
  echo "Illegal arguments, e.g. build-docker.sh gpu captcha-train 0.1"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@

docker build -t ${DOCKER_TAG} \
  --build-arg device_type=${DEVICE_TYPE} \
  --build-arg project_home_in_docker=${DOCKER_HOME} \
  -f ${PROJECT_HOME}/dockers/Dockerfile.service ${PROJECT_HOME}

