#!/bin/bash
# Script to start jupyter notebook

set -e

curr_dir=$(dirname $0)
. ${curr_dir}/start.sh jupyter notebook $@
