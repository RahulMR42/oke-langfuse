## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "nsg_name" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "subnets_cidrs" {
  type = any
}
