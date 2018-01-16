#!/bin/bash

# system settings
PYTHON=`which python`

# project settings
PROJECT_BIN=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PROJECT_HOME=${PROJECT_BIN}/..
DATA_DIR=~/opt/data
LOG_DIR=~/opt/log
