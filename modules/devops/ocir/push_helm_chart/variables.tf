## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "region" {
  type = string
}

variable "oci_profile" {
  type    = string
  default = "DEFAULT"
}

variable "compartment_id" {
  type = string
}

variable "object_storage_namespace" {
  type = string
}

variable "oss_charts_repo_prefix" {
  type = string
}

variable "chart" {
  type = any
}
