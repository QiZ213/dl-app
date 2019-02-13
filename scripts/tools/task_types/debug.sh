#!/bin/bash
# Settings to start a debug environment

# building parameters
IMAGE_EXISTED="yes"

# running parameters
RUNNING_MODE="-it"
RUNNING_OPTS="--net=bridge"
RUNNING_OPTS+=" -p ${SERVING_PORT:=18080}:8080"
RUNNING_OPTS+=" --entrypoint ''"
RUNNING_OPTS+=" -v ${TARGET_HOME}/data:${DOCKER_DATA_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/log:${DOCKER_LOG_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/models:${DOCKER_MODEL_DIR}"
CMD="bash"
