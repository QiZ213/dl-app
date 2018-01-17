#!/bin/bash
if [ $# -lt 4 ]; then
  echo "Illegal arguments: ./run-service.sh idc_name device_type service version"
  echo "e.g. $ /bin/bash run-service.sh prod cpu captcha-service 0.1"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@

! test -d ${PROJECT_HOME}/log && mkdir -p ${PROJECT_HOME}/log

CMD="/bin/bash ${DOCKER_HOME}/bin/start-service.sh"
${DOCKER} ps -a | grep ${PROJECT_NAME} && ${DOCKER} stop ${PROJECT_NAME} && ${DOCKER} rm -v ${PROJECT_NAME}
${DOCKER_ENGINE} run -d \
  --net=bridge \
  --name ${PROJECT_NAME} \
  -p 18080:8080 \
  -v ${PROJECT_HOME}/log:${DOCKER_HOME}/log \
  ${DOCKER_TAG} ${CMD} \
  || { echo "fail to run ${DOCKER_TAG}" && exit 64; }

echo "start ${DOCKER_TAG} successfully"
