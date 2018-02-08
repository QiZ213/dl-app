#!/bin/bash
if [ $# -lt 4 ]; then
  echo "Illegal arguments: ./run-service.sh idc_name device_type service version image_existed"
  echo "e.g. $ /bin/bash run-service.sh prod cpu captcha-service 0.1 yes"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@
IMAGE_EXISTED=$5

DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.service"

if [ "${IMAGE_EXISTED}" = "no" ]; then
  echo "build serving docker image ${DOCKER_TAG} from ${DOCKER_FILE}"
  echo "build args: ${BUILDING_ARGS}"
  delete_docker_container ${PROJECT_NAME}
  delete_docker_image ${DOCKER_TAG}
  ${DOCKER} build -t ${DOCKER_TAG} \
    ${BUILDING_ARGS} \
    -f ${DOCKER_FILE} ${PROJECT_HOME} \
    || { echo "fail to build ${DOCKER_TAG}" && delete_docker_image ${DOCKER_TAG} && exit 64; }
  echo "build ${DOCKER_TAG} successfully"
fi

CMD="/bin/bash ${DOCKER_HOME}/bin/start-service.sh"
RUNNING_OPTIONS="${RUNNING_OPTIONS} --net=bridge -p ${SERVING_PORT}:8080"

echo "run serving docker image ${DOCKER_TAG}"
echo "run cmd: ${CMD}"
echo "with options: ${RUNNING_OPTIONS}"
delete_docker_container ${PROJECT_NAME}
${DOCKER_ENGINE} run -d \
  --name ${PROJECT_NAME} \
  ${RUNNING_OPTIONS} \
  ${DOCKER_TAG} ${CMD} \
  || { echo "fail to run ${DOCKER_TAG}" && delete_docker_container ${PROJECT_NAME} && exit 64; }
echo "start ${DOCKER_TAG} successfully"
