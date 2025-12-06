#!/bin/bash 

set -xe

function die { echo "${@}" 1>&2 ; exit 2; }

set -o pipefail

yum install -y python36-oci-cli

mkdir -p /var/lib/kubelet
mkdir -p /root/.docker
ln -s /var/lib/kubelet/config.json /root/.docker/config.json
/root/docker_login.sh || { echo docker login failed ; exit 1; }