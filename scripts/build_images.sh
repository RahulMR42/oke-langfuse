#!/bin/bash

set -e -o pipefail

# set new limits
sudo ulimit -n 4096

# install dependencies
## OCI CLI

sudo yum install -y podman git curl jq sed python3.12 python3.12-pip
python3.12 -m pip install oci-cli

# install nvm to install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
# install node v24
nvm install v24

# install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -
source ~/.bashrc

set -x 

# get info from the instance metadata
export REGION=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".region")
export COMPARTMENT_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".compartmentId")
export TENANCY_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".tenantId")
export INSTANCE_OCID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".id")
export DEPLOY_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".metadata.deploy_id")
export CLUSTER_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".metadata.cluster_id")
export TENANCY_NAMESPACE=$(oci --auth instance_principal os ns get | jq -r ".data")
export PLATFORM=$(podman system info --format json | jq .version.OsArch)
export ARCH=$(podman system info --format json | jq -r .host.arch)
# grow the file system. Building the LangFuse image requires over 40GB
sudo /usr/libexec/oci-growfs -y

# clone the OCI_GenAI_access_gateway repo
rm -rf OCI_GenAI_access_gateway
git clone https://github.com/jin38324/OCI_GenAI_access_gateway.git

pushd OCI_GenAI_access_gateway
# checkout known tag (this repo is not very good at testing and it is best to stay with a known working version)
git checkout ${OCI_GENAI_GATEWAY_TAG:-581e3cb7150404d80b35f7875f0d28d1510d6de8}

ls -lah

## Get registry repo token and docker login again to the repo as token may have expried by then
oci --auth instance_principal raw-request --http-method GET --target-uri https://${REGION}.ocir.io/20180419/docker/token | jq -r .data.token | podman login ${REGION}.ocir.io -u BEARER_TOKEN --password-stdin

## check if container repo exists or create it
podman manifest inspect ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/oci-genai-gateway \
|| oci --auth instance_principal artifacts container repository create \
    --compartment-id ${COMPARTMENT_ID} \
    --display-name ${DEPLOY_ID}/oci-genai-gateway \
    --is-public false \
|| echo "already exists"

# build for this platform. Note we use the same compute image as the OKE nodes for this instance, so we're building for the OKE platform being deployed.
podman build --ulimit=nofile=4096:4096 --platform=${PLATFORM} -t ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/oci-genai-gateway:oci .

## push image to repo
## Get registry repo token and docker login again to the repo as token may have expried by then
oci --auth instance_principal raw-request --http-method GET --target-uri https://${REGION}.ocir.io/20180419/docker/token | jq -r .data.token | podman login ${REGION}.ocir.io -u BEARER_TOKEN --password-stdin

podman push ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/oci-genai-gateway:oci

# get image by SHA
export OCI_GENAI_GATEWAY_IMAGE=$(podman inspect --format='{{index .RepoDigests 0}}' ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/oci-genai-gateway:oci)
popd
# clean up
rm -rf OCI_GenAI_access_gateway

# cache all build layers (faster if running multiple times, for debugging for example)
export BUILDAH_LAYERS=true
# Pull, patch and build Langfuse project
rm -rf langfuse
git clone https://github.com/langfuse/langfuse

pushd langfuse

# get latest version tag for the repo
export LANGFUSE_VERSION=$(git tag --sort=v:refname | tail -1)

# checkout latest tag branch
git checkout $LANGFUSE_VERSION

## patch Langfuse for IDCS. That requires installing the JS dependencies, patching and updating the lock file


# install node modules locally so we can patch openid-client and update the package json to build the container image from lock file
pnpm install
pnpm add openid-client@5.6.5 -w

# get the location of the temporary openid-client module
export TMP_FOLDER=$(pnpm patch openid-client@5.6.5 | grep "pnpm patch-commit" | awk -F" " '{print $3}' | tr -d "'")

# patch the code of the openid-client to allow for 302 redirects to work (used by IDCS)
sed -i 's|const http = |//const http = |gm' ${TMP_FOLDER}/lib/helpers/request.js
sed -i 's|const https = |//const https = |gm' ${TMP_FOLDER}/lib/helpers/request.js
sed -i '5i\const { http, https } = require('follow-redirects');' ${TMP_FOLDER}/lib/helpers/request.js

# commit the openid-client patch
pnpm patch-commit ${TMP_FOLDER}

## update the lock file
pnpm update

# clean up the node_modules
rm -rf node_modules

export VERSION=${LANGFUSE_VERSION:-latest}-oci

## Check if repo exists or create it
podman manifest inspect ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/langfuse \
|| oci --auth instance_principal artifacts container repository create \
    --compartment-id ${COMPARTMENT_ID} \
    --display-name ${DEPLOY_ID}/langfuse \
    --is-public false \
|| echo "already exists"

# build and publish the LangFuse container image
podman build --ulimit=nofile=4096:4096 --platform=${PLATFORM} --shm-size=10G -t ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/langfuse:${VERSION} --build-arg NEXT_PUBLIC_BASE_PATH=/langfuse -f ./web/Dockerfile .
podman push ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/langfuse:${VERSION}

# get image by SHA
export LANGFUSE_IMAGE=$(podman inspect --format='{{index .RepoDigests 0}}' ${REGION}.ocir.io/${TENANCY_NAMESPACE}/${DEPLOY_ID}/langfuse:${VERSION})

popd

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
chmod +x kubectl
mv -f kubectl ~/.local/bin/kubectl

# get the kubeconfig
rm -f $HOME/.kube/config
oci --auth instance_principal ce cluster create-kubeconfig --cluster-id ${CLUSTER_ID} --file $HOME/.kube/config --region ${REGION} --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT
# edit the kubeconfig to be able to use instance principal auth
sed -i '23i\      - --auth' $HOME/.kube/config
sed -i '24i\      - instance_principal' $HOME/.kube/config

kubectl get pods -A 

# ## Get cluster kubeconfig
# # oci ce cluster create-kubeconfig --cluster-id ${CLUSTER_ID} --file $HOME/.kube/config --region ${REGION} --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT --auth resource_principal

# cat ../../../kubeconfig
# export KUBECONFIG=../../../kubeconfig

# ## Clone the repo
# rm -rf OCI_GenAI_access_gateway
# git clone https://github.com/jin38324/OCI_GenAI_access_gateway.git
# pushd OCI_GenAI_access_gateway

# git checkout ${OCI_GENAI_GATEWAY_TAG:-581e3cb7150404d80b35f7875f0d28d1510d6de8}

## generate the manifest

#eval "echo \"$(cat ./manifests/genai_gateway.Deployment.template.yaml)\"" > genai_gateway.Deployment.yaml

#cat genai_gateway.Deployment.yaml


## Start SSH proxy to K8S API

#ssh -o StrictHostKeyChecking=accept-new -i bastionKey.pem -N -D 127.0.0.1:1088 -p 22 ${BASTION_SESSION_ID}@host.bastion.${REGION}.oci.oraclecloud.com &
#PROXY_PID=$!

#export HTTP_PROXY="socks5://127.0.0.1:1088"
#export HTTPS_PROXY="socks5://127.0.0.1:1088"

## deploy the manifest
# validate manifest

#pip install PySocks

#kubectl get pods -A

#kubectl apply -f genai_gateway.Deployment.yaml --dry-run=client -o yaml
# no validation on apply this time as it fails when using the proxy
#kubectl apply -n ${LANGFUSE_K8S_NAMESPACE} -f genai_gateway.Deployment.yaml --wait --validate=false

#kill $PROXY_PID


# Schedule termination of this instance
