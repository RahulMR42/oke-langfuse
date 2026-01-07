## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "project_id" {
  type = string
}

variable "target_cluster" {
  type        = any
  description = "The OKE cluster object"
}

variable "defined_tags" {
  type = any
}
