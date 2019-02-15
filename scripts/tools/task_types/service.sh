#!/bin/bash
# settings to start a service task

# building parameters
DOCKER_FILE="${TARGET_HOME}/dockers/Dockerfile.service"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE}"
BUILDING_ARGS+=" --build-arg project_home_in_docker=${DOCKER_HOME}"
BUILDING_ARGS+=" --build-arg project_name=${TASK_NAME}"
BUILDING_ARGS+=" --build-arg module_name=${MODULE_NAME}"

# running parameters
RUNNING_OPTS="-d --restart=unless-stopped"
RUNNING_OPTS+=" --net=bridge -p ${SERVING_PORT:=18080}:8080"
RUNNING_OPTS+=" -v ${TARGET_HOME}/data:${DOCKER_DATA_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/log:${DOCKER_LOG_DIR}"
RUNNING_OPTS+=" -v ${TARGET_HOME}/models:${DOCKER_MODEL_DIR}"

# helping parameters
HELLO_URL=$(blue_echo "http://${IP}:${SERVING_PORT}")
API_URL=$(blue_echo "http://${IP}:${SERVING_PORT}/service")
TIPS="Could the service be launched? Call ${HELLO_URL} and get $(green_echo Hello! Service is running).\n"
TIPS+="Call your application from ${API_URL}\n"
TIPS+="Check running log by: $(green_echo docker logs -f ${TASK_NAME})"
