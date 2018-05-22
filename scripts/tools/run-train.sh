#!/bin/bash
if [ $# -lt 6 ]; then
  echo "Illegal arguments: ./run-train.sh idc_name device_type task_name version image_existed debug_mode [notebook_enabled]"
  echo "e.g. $ /bin/bash run-train.sh prod cpu captcha-train 0.1 no yes [yes]"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-helper.sh $@
IMAGE_EXISTED=$5
DEBUG_MODE=$6
shift
NOTEBOOK_ENABLED=$6

if [ "${NOTEBOOK_ENABLED}" = "yes" ]; then
  DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_base_url=${PROJECT_NAME}"
  CMD="/bin/bash -c start-notebook.sh"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/notebooks:/home/ppd"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -p ${NOTEBOOK_PORT:=18888}:8888"
else
  DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.train"
  CMD="/bin/bash -c ${DOCKER_HOME}/bin/train-model.sh"
fi

if [ "${IMAGE_EXISTED}" == "yes" ]; then
    echo "use old ${DOCKER_TAG}"
else
  echo "building training docker image ${DOCKER_TAG} by:"
  delete_docker_container ${DOCKER_TAG}
  delete_docker_image ${DOCKER_TAG}

  BUILDING_CMD="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${PROJECT_HOME} "
  echo "${BUILDING_CMD}"

  eval ${BUILDING_CMD} || {
    echo "fail to build ${DOCKER_TAG}" \
        && delete_docker_image $1 \
        && exit 64;
  }
  echo "build ${DOCKER_TAG} successfully"
fi

echo "running training docker image ${DOCKER_TAG} by:"
delete_docker_container ${PROJECT_NAME}

if [ "${DEBUG_MODE}" = "yes" ]; then
  RUNNING_CMD="${DOCKER_ENGINE} run -it --name ${PROJECT_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
  echo "${RUNNING_CMD}"

  eval ${RUNNING_CMD} || {
    echo "fail to start ${DOCKER_TAG} by ${CMD}" \
        && delete_docker_container ${PROJECT_NAME} \
        && exit 64;
  }
else
  RUNNING_CMD="${DOCKER_ENGINE} run -d --name ${PROJECT_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
  echo "${RUNNING_CMD}"

  eval ${RUNNING_CMD} || {
    echo "fail to start ${DOCKER_TAG} by ${CMD}" \
        && delete_docker_container ${PROJECT_NAME} \
        && exit 64;
  }
  check_application_status ${PROJECT_NAME}

  echo "start ${DOCKER_TAG} successfully"
fi
