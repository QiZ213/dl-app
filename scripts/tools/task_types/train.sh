#!/bin/bash
# settings to start a training task

# building parameters
DOCKER_FILE="${TARGET_HOME}/dockers/Dockerfile.train"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE}"
BUILDING_ARGS+=" --build-arg project_home_in_docker=${DOCKER_HOME}"
BUILDING_ARGS+=" --build-arg project_name=${TASK_NAME}"
BUILDING_ARGS+=" --build-arg train_user=$(whoami) "
BUILDING_ARGS+=" --build-arg train_uid=$(id -u)"
BUILDING_ARGS+=" --build-arg train_gid=$(id -g)"

# running parameters
RUNNING_MODE="-d"
RUNNING_OPTS="-v ${TARGET_HOME}/data:${DOCKER_DATA_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/log:${DOCKER_LOG_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/models:${DOCKER_MODEL_DIR}"