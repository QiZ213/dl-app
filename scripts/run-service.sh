#!/bin/bash
if [ $# -lt 3 ]; then
  echo "Illegal arguments, e.g. run-docker.sh gpu captcha-train 0.1"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/docker-settings.sh $@

! test -d ${PROJECT_HOME}/log && mkdir -p ${PROJECT_HOME}/log

CMD="/bin/bash ${DOCKER_HOME}/bin/start-service.sh"
${DOCKER_ENGINE} run -it \
  --net=bridge \
  -p 8080:8080 \
  -v ${PROJECT_HOME}/log:${DOCKER_HOME}/log \
  ${DOCKER_TAG} ${CMD}
