#!/bin/bash
# Settings to start a prune notebook with production environment

if [[ ! -e ${TARGET_HOME}/requirements_production.txt ]]; then
  die "No such file or directory: '${TARGET_HOME}/requirements_production.txt'"
fi

# building parameters
DOCKER_FILE="${TARGET_HOME}/dockers/notebook/Dockerfile.ppd-prod-notebook"
BUILDING_ARGS="--build-arg base=base:py36-cpu-centos7"
BUILDING_ARGS+=" --build-arg notebook_base_url=${TASK_NAME}"
BUILDING_ARGS+=" --build-arg notebook_user=$(whoami)"
BUILDING_ARGS+=" --build-arg notebook_uid=$(id -u)"
BUILDING_ARGS+=" --build-arg notebook_gid=$(id -g)"

# running parameters
RUNNING_OPTS="-d --restart=unless-stopped"
RUNNING_OPTS+=" --add-host nexus3.love:10.1.62.214"
RUNNING_OPTS+=" -v ${TARGET_HOME}/notebooks:/home/$(whoami)"
RUNNING_OPTS+=" -p ${NOTEBOOK_PORT:=18888}:8888"
CMD="start_notebook.sh"


# helping parameters
URL=$(blue_echo "http://${IP}:${NOTEBOOK_PORT}/${TASK_NAME}")
TIPS="Access notebook from ${URL} Use default password\n"
TIPS+="Move files in: $(green_echo ${NOTEBOOK_DIR:=$(get_default_base_dir)/dl-notebooks/${TASK_NAME}})\n"
TIPS+="Check running log by: $(green_echo docker logs -f ${TASK_NAME})"
