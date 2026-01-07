## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "argument_substitution_mode" {
  default = "NONE"
  type    = string
}

variable "chart_url" {
  type = string
}

variable "chart_version" {
  type = string
}

variable "display_name" {
  type = string
}

variable "defined_tags" {
  type = any
}

variable "project_id" {
  type = string
}
