#!/bin/bash
# settings to start an unit-test environment

# building parameters
DOCKER_FILE="${TARGET_HOME}/dockers/Dockerfile.test"
DOCKER_BASE="${SOURCE_REGISTRY}/${DEEP_LEARNING_VERSION}-${PYTHON_ALIAS}-cpu-${OS_VERSION}"
BUILDING_ARGS="--build-arg base=${DOCKER_BASE}"

# running parameters
BUILD_ONLY="yes"
