#!/bin/bash
# Script to start deep learning application service

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/common_settings.sh

dl_service \
  --port=8080 \
  --json_conf="${PROJECT_HOME}/confs/conf.json"
