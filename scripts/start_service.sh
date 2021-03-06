#!/bin/bash
# Script to start deep learning application service

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/common_settings.sh

${curr_dir}/start.sh dl_service \
  --port=8080 \
  --base_json_conf="${PROJECT_HOME}/confs/base_conf.json" \
  --update_json_confs="${PROJECT_HOME}/confs/conf.json"