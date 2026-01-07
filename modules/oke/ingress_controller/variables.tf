variable "compartment_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "devops_project_id" {
  type = string
}

variable "devops_environment_id" {
  type = string
}

variable "defined_tags" {
  type = any
  default = {}
}

variable "force_deployment" {
  type    = bool
  default = false
}