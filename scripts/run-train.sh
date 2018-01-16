#!/bin/bash
if [ $# -lt 4 ]; then
  echo "Illegal arguments: ./run-train.sh idc_name device_type task version"
  echo "e.g. $ /bin/bash run-train.sh prod cpu captcha-train 0.1"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@

! test -d ${PROJECT_HOME}/log && mkdir -p ${PROJECT_HOME}/log
! test -d ${PROJECT_HOME}/model && mkdir -p ${PROJECT_HOME}/model

${DOCKER} ps -a | grep ${PROJECT_NAME} && ${DOCKER} stop ${PROJECT_NAME} && ${DOCKER} rm -v ${PROJECT_NAME}
${DOCKER_ENGINE} run -it \
  --name ${PROJECT_NAME} \
  -v ${DATA_DIR}:${DOCKER_HOME}/data \
  -v ${PROJECT_HOME}/model:${DOCKER_HOME}/model \
  -v ${PROJECT_HOME}/log:${DOCKER_HOME}/log \
  ${DOCKER_TAG} \
  || { echo "fail to run ${DOCKER_TAG}" && ${DOCKER} stop ${PROJECT_NAME} && ${DOCKER} rm -v ${PROJECT_NAME} && exit 64; }

echo "train ${DOCKER_TAG} successfully"