#!/bin/bash
# Script to help process with ftp
. "${BASH_SOURCE%/*}/../common_settings.sh"

FTP_USER="bird"
FTP_PASSWORD="PPDai.com"
FTP_HOST="54.223.218.130"
FTP="lftp -u "${FTP_USER},${FTP_PASSWORD}" ${FTP_HOST}"
FTP_CMD_BASE="set net:limit-rate 800000:500000;"

act_if_cond(){
  success_cond=$1
  success_act=$2
  if [[ -n ${success_cond} ]] ; then
    eval "${success_act}"
    return 0
  fi
}

wait_for_condition(){
  total=$1
  interval=$2
  success_cond=$3
  success_act=$4
  i=1
  while [[ $((total--)) -gt 0 ]]; do
    act_if_cond "${success_cond}" "${success_act}" && return 0
    echo "sleep for ${interval}, $((i++)) times"
    sleep ${interval}
  done
  act_if_cond "${success_cond}" "${success_act}" && return 0
  return 65
}