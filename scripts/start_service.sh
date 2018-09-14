#!/bin/bash
# Script to start deep learning application service

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/start.sh dl_service \
  --port=8080 \
  --json_conf="${PROJECT_HOME}/confs/conf.json"
