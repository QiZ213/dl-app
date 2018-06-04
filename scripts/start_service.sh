#!/bin/bash
# Script to start deep learning application service

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/common_settings.sh

${PYTHON} ${PROJECT_HOME}/application/service/flask/gunicorn_server.py  \
  --port=8080 \
  --json_conf="${PROJECT_HOME}/confs/conf.json"
