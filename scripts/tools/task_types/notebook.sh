#!/bin/bash
# Settings to start a prune notebook

# building parameters
DOCKER_FILE="${PROJECT_HOME}/dockers/notebook/Dockerfile.ppd-notebook"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE}"
BUILDING_ARGS+=" --build-arg notebook_password=${NOTEBOOK_PASSWORD:=123456}"
BUILDING_ARGS+=" --build-arg notebook_base_url=${TASK_NAME}"
BUILDING_ARGS+=" --build-arg notebook_user=$(whoami)"
BUILDING_ARGS+=" --build-arg notebook_uid=$(id -u)"
BUILDING_ARGS+=" --build-arg notebook_gid=$(id -g)"

# running parameters
RUNNING_OPTS="-d --restart=unless-stopped"
RUNNING_OPTS+=" -v ${TARGET_HOME}/notebooks:/home/$(whoami)"
RUNNING_OPTS+=" -p ${NOTEBOOK_PORT:=18888}:8888"
CMD="start_notebook.sh"


# helping parameters
URL=$(blue_echo "http://${IP}:${NOTEBOOK_PORT}/${TASK_NAME}")
TIPS="Access notebook from ${URL} Use default password\n"
TIPS+="Move files in: $(green_echo ${NOTEBOOK_DIR:=$(get_default_base_dir)/dl-notebooks/${TASK_NAME}})\n"
TIPS+="Check running log by: $(green_echo docker logs -f ${TASK_NAME})"
