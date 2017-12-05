#!/bin/bash
curr_dir=$(dirname $0)
. ${curr_dir}/../env.sh

python ${PROJECT_HOME}/codes/service/ucloud/server.py  \
  --port=8080 \
  --json_conf="${PROJECT_HOME}/confs/captcha-conf.ucloud.json"
