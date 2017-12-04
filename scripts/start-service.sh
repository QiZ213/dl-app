#!/bin/bash
curr_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
source ${curr_dir}/env.sh

python ${PROJECT_HOME}/codes/service/flask/gunicorn_server.py  \
  --port=8080 \
  --json_conf="${PROJECT_HOME}/confs/captcha-conf.json"
