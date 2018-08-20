#!/bin/bash

curr_dir=${BASH_SOURCE%/*}
. ${curr_dir}/../common_utils.sh

if [[ $# -lt 5 ]]; then
  red_echo "Illegal arguments: ./launch.sh idc_name device_type task_name version task_type [image_existed]"
  echo "e.g. $ /bin/bash launch.sh ppd|aws cpu|gpu ocr-train 0.1 service|train|notebook|debug [no]"
  exit 128
fi

. ${curr_dir}/docker_helpers.sh $@
TASK_TYPE=$5
shift
IMAGE_EXISTED=$5

if [[ "${TASK_TYPE}" = "service" ]]; then
  DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.service"
  CMD="/bin/bash ${DOCKER_HOME}/bin/start_service.sh"
  RUNNING_MODE="-d --restart=unless-stopped"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} --net=bridge -p ${SERVING_PORT}:8080"
elif  [[ "${TASK_TYPE}" = "train" ]]; then
  DOCKER_FILE="${PROJECT_HOME}/dockers/Dockerfile.train"
  CMD="/bin/bash -c ${DOCKER_HOME}/bin/train_model.sh"
  RUNNING_MODE="-d"
elif [[ "${TASK_TYPE}" = "notebook" ]]; then
  DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg notebook_base_url=${PROJECT_NAME}"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg nb_user=$(whoami)"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg nb_uid=$(id -u)"
  BUILDING_ARGS="${BUILDING_ARGS} --build-arg nb_gid=$(id -g)"
  CMD="/bin/bash -c start_notebook.sh"
  RUNNING_MODE="-d --restart=unless-stopped"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -v ${PROJECT_HOME}/notebooks:/home/$(whoami)"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} -p ${NOTEBOOK_PORT:=18888}:8888"
elif [[ "${TASK_TYPE}" = "debug" ]]; then
  IMAGE_EXISTED="yes"
  CMD="/bin/bash"
  RUNNING_MODE="-it"
  RUNNING_OPTIONS="${RUNNING_OPTIONS} --net=bridge -p ${SERVING_PORT}:8080"
else
  red_echo "unsupported task type: ${TASK_TYPE}"
  exit 64
fi

DOCKER_TAG="${PROJECT_NAME}:${PROJECT_VERSION}"
if [[ "${IMAGE_EXISTED}" == "yes" ]]; then
  if ! ${DOCKER} image inspect ${DOCKER_TAG} &> /dev/null ; then
    ${DOCKER} pull ${DOCKER_REGISTRY}/${DOCKER_TAG} || {
      red_echo "failed to pull ${DOCKER_TAG} from ${DOCKER_REGISTRY}" \
        && exit 64;
    }
    ${DOCKER} tag ${DOCKER_REGISTRY}/${DOCKER_TAG} ${DOCKER_TAG}
  fi
  echo "use existed docker image ${DOCKER_TAG} successfully"
else
  echo "building ${TASK_TYPE} docker image ${DOCKER_TAG} by:"
  delete_docker_container ${DOCKER_TAG}
  delete_docker_image ${DOCKER_TAG}
  BUILDING_CMD="${DOCKER} build -t ${DOCKER_TAG} ${BUILDING_ARGS} -f ${DOCKER_FILE} ${PROJECT_HOME} "
  blue_echo "${BUILDING_CMD}"
  eval ${BUILDING_CMD} || {
    red_echo "failed to build ${DOCKER_TAG}" \
      && delete_docker_image $1 \
      && exit 64;
  }
  echo "build ${DOCKER_TAG} successfully"
fi

echo "running ${TASK_TYPE} docker image ${DOCKER_TAG} by:"
delete_docker_container ${PROJECT_NAME}
RUNNING_CMD="${DOCKER_ENGINE} run ${RUNNING_MODE} --name ${PROJECT_NAME} ${RUNNING_OPTIONS} ${DOCKER_TAG} ${CMD}"
blue_echo "${RUNNING_CMD}"
eval ${RUNNING_CMD} || {
    red_echo "failed to start ${DOCKER_TAG} by ${CMD}" \
      && delete_docker_container ${PROJECT_NAME} \
      && exit 64;
  }
if [[ "${TASK_TYPE}" != "debug" ]]; then
  check_application_status ${PROJECT_NAME}
  echo "start ${DOCKER_TAG} successfully"
fi

case "${TASK_TYPE}" in
  notebook)
    TIPS="Access notebook from"
    URL=$(blue_echo "http://start_the_service_IP:${NOTEBOOK_PORT}/${PROJECT_NAME}")
    echo "${TIPS} ${URL}. Use default password"
    ;;
  service)
    TIPS1="Test if service has been launched from"
    HELLO_URL=$(blue_echo "http://start_the_service_IP:${SERVING_PORT}")
    echo -e "${TIPS1} ${HELLO_URL}, and get $(green_echo Hello! Service is running) ."

    TIPS2="Call your application from"
    API_URL=$(blue_echo "http://start_the_service_IP:${SERVING_PORT}/service")
    echo -e "${TIPS2} ${API_URL}"
    ;;
esac

