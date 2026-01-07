## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  manifest_yaml = templatefile("${path.module}/manifests/genai_gateway.Deployment.template.yaml", {
    OCI_GENAI_GATEWAY_IMAGE = "${var.region}.ocir.io/${var.tenancy_namespace}/${var.deploy_id}/oci-genai-gateway:oci"
    AUTH_TYPE               = "INSTANCE_PRINCIPAL"
    REGION                  = var.genai_region
    COMPARTMENT_ID          = var.compartment_id
  })
}
