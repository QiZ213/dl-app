#!/bin/bash
if [ $# -lt 2 ]; then
  echo "Illegal arguments: init-docker-registry-client.sh idc os [remote_certs]"
  echo "e.g. $ /bin/bash init-docker-registry-client.sh prod linux"
  exit 128
fi

curr_dir=$(dirname $0)
. ${curr_dir}/common-settings.sh

IDC_NAME=$1
OS=$2
REMOTE_CERTS_DIR=$3
REMOTE_CERTS_DIR=${REMOTE_CERTS_DIR:=/opt/dl-dockers/certs}

if [ ${IDC_NAME} == 'prod' ]; then
  DOCKER_REGISTRY="registry.ppdai.com"
  DOCKER_HOST="172.20.66.81"
  DOCKER_INNER_HOST="172.20.66.81"
  DOCKER_USER="dashuju"
elif [ ${IDC_NAME} == 'aws' ]; then
  DOCKER_REGISTRY="registry.ppdai.aws"
  DOCKER_HOST="52.80.59.222"
  DOCKER_INNER_HOST="172.31.3.112"
  DOCKER_USER="ubuntu"
else
  echo "unsupported idc: ${IDC_NAME}"
  exit 64
fi

if [ ${OS} == 'linux' ]; then
  DOCKER_CERTS_DIR=/etc/docker/certs.d/${DOCKER_REGISTRY}
elif [ ${OS} == 'mac' ]; then
  DOCKER_CERTS_DIR=~/.docker/certs.d/${DOCKER_REGISTRY}
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
scp ${DOCKER_USER}@${DOCKER_HOST}:${REMOTE_CERTS_DIR}/domain.crt ${TMP_CERTS_DIR}/. \
  || { echo "fail to copy from ${DOCKER_USER}@${DOCKER_HOST}:${REMOTE_CERTS_DIR}/domain.crt" && exit 69; }

cd ${TMP_CERTS_DIR}
# gen client cert and key
openssl genrsa -out client.key 4096
openssl req -new -x509 -text -key client.key -out client.cert -subj "/CN=${DOCKER_REGISTRY}"

# copy to docker certs
sudo test -d ${DOCKER_CERTS_DIR} || sudo mkdir -p ${DOCKER_CERTS_DIR}
sudo cp client.cert client.key domain.crt ${DOCKER_CERTS_DIR}/
cd ..

if [ ${OS} == 'linux' ]; then
  sudo service docker restart
else
  echo "please restart docker service manually"
fi

# add to /etc/hosts
sudo grep "${DOCKER_INNER_HOST} ${DOCKER_REGISTRY}" /etc/hosts \
  || echo "please add \"${DOCKER_INNER_HOST} ${DOCKER_REGISTRY}\" to /etc/hosts manually"
