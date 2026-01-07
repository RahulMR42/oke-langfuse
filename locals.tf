## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  kubernetes_version     = "v${module.kubernetes_version.versions.selected}"
  cluster_name           = "${substr(var.cluster_name, 0, 200)}-${random_string.deploy_id.result}"
  cluster_name_sanitized = replace(local.cluster_name, " ", "_")
}
