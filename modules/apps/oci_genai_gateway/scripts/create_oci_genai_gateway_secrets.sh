#!/bin/bash 
## Copyright © 2022-2026, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

set -e -o pipefail

# oci-genai-gateway default API key value
kubectl get secret oci-genai-gateway -n langfuse \
&& kubectl delete secret oci-genai-gateway -n langfuse

kubectl create secret generic oci-genai-gateway \
--namespace langfuse \
--from-literal="DEFAULT_API_KEYS"="${default_api_keys}"
