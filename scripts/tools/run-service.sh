#!/bin/bash
if [ $# -lt 6 ]; then
  echo "Illegal arguments: ./run-service.sh idc_name device_type service_name version image_existed debug_mode"
  echo "e.g. $ /bin/bash run-service.sh ppd|aws cpu|gpu ocr-service 0.1 yes|no yes|no"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-helper.sh $@
IMAGE_EXISTED=$5
DEBUG_MODE=$6

DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.service"

if [ "${IMAGE_EXISTED}" = "yes" ]; then
  echo "use old ${DOCKER_TAG}"
else
  echo "building serving docker image ${DOCKER_TAG} by:"
  delete_docker_container ${PROJECT_NAME}
  delete_docker_image ${DOCKER_TAG}

  BUILDING_CMD="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${PROJECT_HOME}"
  echo "${BUILDING_CMD}"

  eval ${BUILDING_CMD} || {
    echo "fail to build ${DOCKER_TAG} from ${DOCKER_FILE}" \
        && delete_docker_image $1 \
        && exit 64;
  }
  echo "build ${DOCKER_TAG} successfully"
fi

echo "running serving docker image ${DOCKER_TAG} by:"
delete_docker_container ${PROJECT_NAME}

if [ "${DEBUG_MODE}" = "yes" ]; then
    CMD="/bin/bash"
    RUNNING_OPTIONS="${RUNNING_OPTIONS} --net=bridge -p ${SERVING_PORT}:8080"
    RUNNING_CMD="${DOCKER_ENGINE} run -it --name ${PROJECT_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
    echo ${RUNNING_CMD}

    eval ${RUNNING_CMD} || {
      echo "fail to start ${DOCKER_TAG} by ${CMD}" \
          && delete_docker_container ${PROJECT_NAME} \
          && exit 64;
    }
else
    CMD="/bin/bash ${DOCKER_HOME}/bin/start-service.sh"
    RUNNING_OPTIONS="${RUNNING_OPTIONS} --net=bridge -p ${SERVING_PORT}:8080"
    RUNNING_CMD="${DOCKER_ENGINE} run -d --name ${PROJECT_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
    echo ${RUNNING_CMD}

    eval ${RUNNING_CMD} || {
      echo "fail to start ${DOCKER_TAG} by ${CMD}" \
          && delete_docker_container ${PROJECT_NAME} \
          && exit 64;
    }
    check_application_status ${PROJECT_NAME}

    echo "start ${DOCKER_TAG} successfully"
fi
