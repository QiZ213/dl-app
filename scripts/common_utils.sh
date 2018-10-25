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
    if [ ${num} -eq 0 ]; then
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
  local dir_existed=0
  [[ -d $1 ]] && dir_existed=1
  mkdir -p $1
  echo $(cd $1 && pwd)
  if [[ dir_existed == 0 ]]; then
   # remove dir if it is created
   test -d $1 && rm -r $1
  fi
}

copy_missing(){
  src=$1
  tgt=$2
  shift 2
  [[ -d ${tgt} ]] || mkdir -p ${tgt}
  if [[ -z "$1" ]]; then
    cp -nr ${src} ${tgt}
  else
    for i in $@; do
      parent_dir=${i%/*}
      [[ "${parent_dir}" != "$i" ]] && mkdir -p ${tgt}/${parent_dir}
      cp -nr ${src}/${i} ${tgt}/${parent_dir}
      die_if_err "fail to copy ${src}/${i} to ${tgt}/${parent_dir}"
    done;
  fi
}
