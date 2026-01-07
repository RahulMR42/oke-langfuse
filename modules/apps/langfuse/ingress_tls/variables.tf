variable "builder_details" {
  type = map(any)
}

variable "langfuse_hostname" {
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