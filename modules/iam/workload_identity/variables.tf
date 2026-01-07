## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "create_policy" {
  default = true
}
variable "compartment_id" {
  type = string
}

variable "workload_name" {
  type = string
}
variable "namespace" {
  type = string
}
variable "service_account_name" {
  type = string
}
variable "cluster_id" {
  type = string
}
variable "permissions" {
  type = list(string)
}
variable "defined_tags" {
  default = null
}
