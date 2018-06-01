#!/bin/bash
# Script to start training

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/common-settings.sh

${PYTHON} ${PROJECT_HOME}/application/model_trainer.py
