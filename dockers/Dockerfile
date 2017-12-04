ARG device_type
FROM ppd:${device_type}-base

# assembling project structure
ARG project_home_in_docker
ENV PROJECT_HOME_IN_DOCKER=${project_home_in_docker}
ADD ./codes ${PROJECT_HOME_IN_DOCKER}/codes
ADD ./scripts ${PROJECT_HOME_IN_DOCKER}/bin
RUN mkdir -p ${PROJECT_HOME_IN_DOCKER}/model ${PROJECT_HOME_IN_DOCKER}/data ${PROJECT_HOME_IN_DOCKER}/log

# executing command to start train
CMD /bin/bash ${PROJECT_HOME_IN_DOCKER}/bin/train-model.sh
