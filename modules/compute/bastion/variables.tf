## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "compartment_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bastion_client_cidr_block_allow_list" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "bastion_name" {
  type    = string
  default = "bastion"
}
