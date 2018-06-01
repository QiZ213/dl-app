#!/bin/bash
if [ $# -lt 4 ]; then
  echo "Illegal arguments: init-docker-registry-client-by-certs.sh registry_ip registry_name os remote_certs"
  echo "e.g. $ /bin/bash init-docker-registry-client.sh 172.31.14.82 registry.ppdai.aws linux bird@172.31.14.82:/opt/dl-dockers/certs"
  exit 128
fi
curr_dir=$(dirname $0)

REGISTRY_IP=$1
REGISTRY_NAME=$2
OS=$3
REMOTE_CERTS_DIR=$4

if [ ${OS} == 'linux' ]; then
  DOCKER_CERTS_DIR=/etc/docker/certs.d/${REGISTRY_NAME}
elif [ ${OS} == 'mac' ]; then
  DOCKER_CERTS_DIR=~/.docker/certs.d/${REGISTRY_NAME}
else
  echo "unsupported os: ${OS}"
  exit 64
fi

sudo test -e ${DOCKER_CERTS_DIR}/domain.crt \
  && echo "client certs already existed" && exit 0

# make tmp dir
TMP_CERTS_DIR="tmp_certs_dir"
mkdir -p ${TMP_CERTS_DIR}
trap "rm -rf ${TMP_CERTS_DIR}" EXIT

# get server cert
scp ${REMOTE_CERTS_DIR}/domain.crt ${TMP_CERTS_DIR}/. \
    || { echo "fail to copy from ${REMOTE_CERTS_DIR}/domain.crt" && exit 69; }

# gen client cert and key, and copy it to destination
cd ${TMP_CERTS_DIR}
openssl genrsa -out client.key 4096
openssl req -new -x509 -text -key client.key -out client.cert -subj "/CN=${DOCKER_REGISTRY}"
sudo test -d ${DOCKER_CERTS_DIR} || sudo mkdir -p ${DOCKER_CERTS_DIR}
sudo cp client.cert client.key domain.crt ${DOCKER_CERTS_DIR}/
cd ..

if [ ${OS} == 'linux' ]; then
  sudo service docker restart
else
  echo "please restart docker service manually"
fi
