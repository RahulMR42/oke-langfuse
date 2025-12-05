#!/bin/bash 

# set -xe

# function die { echo "${@}" 1>&2 ; exit 2; }

# set -o pipefail

yum install -y python36-oci-cli || exit 0

mkdir -p /var/lib/kubelet || exit 0
mkdir -p /root/.docker || exit 0
ln -s /var/lib/kubelet/config.json /root/.docker/config.json || exit 0
/root/docker_login.sh || { echo docker login failed ; exit 0; }