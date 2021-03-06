#!/bin/bash
# Settings to start a develop environment

# building parameters
DOCKER_FILE="${TARGET_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE}"
BUILDING_ARGS+=" --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
BUILDING_ARGS+=" --build-arg notebook_base_url=${TASK_NAME}"
BUILDING_ARGS+=" --build-arg notebook_user=$(whoami)"
BUILDING_ARGS+=" --build-arg notebook_uid=$(id -u)"
BUILDING_ARGS+=" --build-arg notebook_gid=$(id -g)"

# running parameters
RUNNING_OPTS="-d --restart=unless-stopped"
RUNNING_OPTS+=" -v ${TARGET_HOME}:${TARGET_HOME}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/data:${TARGET_HOME}/data"
RUNNING_OPTS+=" -v ${TARGET_HOME}/log:${TARGET_HOME}/log"
RUNNING_OPTS+=" -v ${TARGET_HOME}/models:${TARGET_HOME}/models"
RUNNING_OPTS+=" -v ${TARGET_HOME}/notebooks:${TARGET_HOME}/notebooks"
RUNNING_OPTS+=" -w=\"${TARGET_HOME}\""
RUNNING_OPTS+=" -p ${NOTEBOOK_PORT:=18888}:8888"
RUNNING_OPTS+=" -p ${SERVING_PORT:=18080}:8080"
RUNNING_OPTS+=" -e RUN_USER=${RUN_USER}"
RUNNING_OPTS+=" -e RUN_UID=${RUN_UID}"
RUNNING_OPTS+=" -e RUN_GID=${RUN_GID}"
RUNNING_OPTS+=" --group-add ${RUN_GID}"
CMD="start_notebook.sh"

# helping parameters
URL=$(blue_echo "http://${IP}:${NOTEBOOK_PORT}/${TASK_NAME}")
TIPS="Access notebook from ${URL} Use default password\n"
TIPS+="Check running log by: $(green_echo docker logs -f ${TASK_NAME})"
