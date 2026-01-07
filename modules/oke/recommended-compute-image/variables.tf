## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

variable "image_id" {
  type        = string
  description = "OCI of the compute image"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}
