#!/bin/bash
curr_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

if [ $# -lt 3 ]; then
  echo "Illegal arguments, e.g. run-docker.sh gpu captcha-train 0.1"
  exit 128
fi
source ${curr_dir}/docker-settings.sh $@

! test -d ${PROJECT_HOME}/log && mkdir -p ${PROJECT_HOME}/log
! test -d ${PROJECT_HOME}/model && mkdir -p ${PROJECT_HOME}/model

${DOCKER_ENGINE} run -it \
  -v ${DATA_DIR}:${DOCKER_HOME}/data \
  -v ${PROJECT_HOME}/model:${DOCKER_HOME}/model \
  -v ${PROJECT_HOME}/log:${DOCKER_HOME}/log \
  ${DOCKER_TAG}
