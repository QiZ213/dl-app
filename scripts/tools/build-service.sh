#!/bin/bash
if [ $# -lt 4 ]; then
  echo "Illegal arguments: ./build-service.sh idc_name device_type service version"
  echo "e.g. $ /bin/bash build-service.sh prod cpu captcha-service 0.1"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@

${DOCKER} image inspect ${DOCKER_TAG} && ${DOCKER} rmi ${DOCKER_TAG}
${DOCKER} build -t ${DOCKER_TAG} \
  --build-arg registry=${DOCKER_REGISTRY} \
  --build-arg device_type=${DEVICE_TYPE} \
  --build-arg project_home_in_docker=${DOCKER_HOME} \
  -f ${PROJECT_HOME}/dockers/Dockerfile.service ${PROJECT_HOME} \
  || { echo "fail to build ${DOCKER_TAG}" && exit 64; }

echo "build ${DOCKER_TAG} successfully"

