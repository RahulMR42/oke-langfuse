## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "compartment_id" {
  type = string
}

variable "display_name" {
  type = string
}
variable "subnet_id" {
  type = string
}

variable "node_count" {
  type    = string
  default = "1"
}

variable "node_memory" {
  type    = string
  default = "16"
}
