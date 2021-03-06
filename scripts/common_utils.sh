#!/bin/bash

# Colors
## blue to echo
blue_echo() {
  echo -e "\033[34m$@\033[0m"
}

## green to echo
green_echo() {
  echo -e "\033[32m$@\033[0m"
}

### Error to warning with blink
red_echo() {
  echo -e "\033[31m$@\033[0m"
}
#
### Error to warning with blink
yellow_echo() {
  echo -e "\033[33m$@\033[0m"
}

colorful() {
  text=$(blue_echo $1)
  sep=\|
  num=-1
  for s in $@; do
    num=$((num+1))
    if [[ ${num} -eq 0 ]]; then
      continue
    fi
    case $((${num} % 4)) in
      0)
        text="${text}${sep}$(blue_echo ${s})" ;;
      1)
        text="${text}${sep}$(green_echo ${s})" ;;
      2)
        text="${text}${sep}$(red_echo ${s})" ;;
      *)
        text="${text}${sep}$(yellow_echo ${s})"
    esac

  done
  echo ${text}
}

is_yes() {
  [[ -n "$1" ]] && [[ "$1" =~ [Yy]([Ee][Ss])*$ ]]
}

not_yes() {
  ! is_yes "$1"
}

is_no() {
  [[ -n "$1" ]] && [[ "$1" =~ [Nn]([Oo])*$ ]]
}

not_no() {
  ! is_no "$1"
}

mute() {
  "$@" &> /dev/null
}

die() {
  # simple stack trace in bash shell
  # please refer:
  #   http://wiki.bash-hackers.org/commands/builtin/caller
  local err_code=$(( $? ? $? : 65 )) frame=0
  echo "die with stack:"
  while caller ${frame}; do
    ((frame++))
  done
  red_echo "ERROR ($err_code): $*"
  exit ${err_code}
}

die_if_err() {
  local err_code=$?
  if (( err_code )); then
    die "$@"
  fi
}

abs_dir_path() {
  [[ -d $1 ]] || die "$1 should be existed dir"
  echo $(cd $1 && pwd)
}

###################################################################
# Copy items not existed in tgt from src to tgt
# Usage:
#   1. copy everything from src to tgt
#     copy_missing src tgt
#   2. copy specified items from src to tgt
#     copy_missing src tgt item1 ... itemN
# Globals:
#   None
# Arguments:
#   src, required, source directory, should be existed
#   tgt, required, target directory
#   items, optional, items in source directory,
#          which should be copied to target directory
# Returns:
#   None
###################################################################
copy_missing(){
  local src=$1
  local tgt=$2
  shift 2

  [[ -d ${tgt} ]] || mkdir -p ${tgt}
  if [[ -z "$1" ]]; then
    cp -nr ${src}/* ${tgt}
  else
    for i in $@; do
      parent_dir=$(dirname ${i})
      [[ "${parent_dir}" != "." ]] && mkdir -p ${tgt}/${parent_dir}
      cp -nr ${src}/${i} ${tgt}/${parent_dir}
    done;
  fi
}


ip_address() {
  if [[ $1 == public ]]; then
    # please refer: https://ip.sb/api/
    curl --silent -4 ip.sb
  else
    # Do not support run by ssh on remote.
    ip addr | grep "inet\ " | grep -v docker0 | grep -v 127.0.0 | head -n 1 | awk '{print $2}' | sed 's/\/.*//'
  fi
}

get_default_base_dir() {
  : ${DEFAULT_BASE_DIR:="/opt"}
  if [[ -w ${DEFAULT_BASE_DIR} ]]; then
    echo ${DEFAULT_BASE_DIR}
  else
    echo ~/${DEFAULT_BASE_DIR#/}
  fi
}
