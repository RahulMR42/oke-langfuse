#!/bin/bash
## Copyright © 2022-2026, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

set -e -o pipefail -x

# get info from the instance metadata
export COMPARTMENT_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".compartmentId")
export DEPLOY_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".metadata.deploy_id")
export CLUSTER_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".metadata.cluster_id")
export SUBNET_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r ".metadata.lb_subnet_id")

export LB_NAME="lb-${DEPLOY_ID}"

eval "printf '%b\n' \"$(<oci_native_ingress_class.yaml)\"" > oci_native_ingress_class_filled.yaml

cat oci_native_ingress_class_filled.yaml

kubectl apply -f oci_native_ingress_class_filled.yaml

sleep 120
