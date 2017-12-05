#!/bin/bash
curr_dir=$(dirname $0)
. ${curr_dir}/env.sh

python ${PROJECT_HOME}/codes/examples/train_captcha.py  \
  --training_set_dir ${PROJECT_HOME}/data/10010 \
  --model_dir ${PROJECT_HOME}/model \
  --log_dir ${PROJECT_HOME}/log
