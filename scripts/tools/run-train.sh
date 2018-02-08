#!/bin/bash
if [ $# -lt 5 ]; then
  echo "Illegal arguments: ./run-train.sh idc_name device_type task version image_existed [notebook_enabled]"
  echo "e.g. $ /bin/bash run-train.sh prod cpu captcha-train 0.1 yes [yes]"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@
IMAGE_EXISTED=$5
shift
NOTEBOOK_ENABLED=$5

DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.train"
if [ "${NOTEBOOK_ENABLED}" = "yes" ]; then
  DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_base_url=${PROJECT_NAME}"
fi

if [ "${IMAGE_EXISTED}" == "no" ]; then
  echo "build training docker image ${DOCKER_TAG} from ${DOCKER_FILE}"
  echo "build args: ${BUILDING_ARGS}"
  delete_docker_image ${PROJECT_NAME}
  delete_docker_image ${DOCKER_TAG}
  docker build -t ${DOCKER_TAG} \
    ${BUILDING_ARGS} \
    -f ${DOCKER_FILE} ${PROJECT_HOME} \
    || { echo "fail to build" && delete_docker_image ${DOCKER_TAG} && exit 64; }
  echo "build ${DOCKER_TAG} successfully"
fi

CMD="/bin/bash -c ${DOCKER_HOME}/bin/train-model.sh"
MODE="-it"
if [ "${NOTEBOOK_ENABLED}" = "yes" ]; then
  CMD="/bin/bash -c start-notebook.sh"
  MODE="-d"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${NOTEBOOK_DIR}:/home/ppd"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -p ${NOTEBOOK_PORT:=18888}:8888"
fi

echo "run training docker image ${DOCKER_TAG}"
echo "run cmd: ${CMD}"
echo "with options: ${RUNNING_OPTIONS}"
delete_docker_container ${PROJECT_NAME}
${DOCKER_ENGINE} run ${MODE} \
  --name ${PROJECT_NAME} \
  ${RUNNING_OPTIONS} \
  ${DOCKER_TAG} ${CMD} \
  || { echo "fail to run ${DOCKER_TAG}" && delete_docker_container ${PROJECT_NAME} && exit 64; }
echo "run ${DOCKER_TAG} successfully"
