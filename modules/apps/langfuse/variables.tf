variable "compartment_id" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "psql_host" {
  type = string
}

variable "psql_cert" {
  type      = string
  sensitive = true
}

variable "psql_password" {
  type      = string
  sensitive = true
}

variable "s3_client_id" {
  type      = string
  sensitive = true
}

variable "s3_client_secret" {
  type      = string
  sensitive = true
}

variable "idcs_client_id" {
  type      = string
  sensitive = true
}

variable "idcs_client_secret" {
  type      = string
  sensitive = true
}

variable "idcs_app_id" {
  type = string
}

variable "redis_hostname" {
  type = string
}

# variable "bastion_session_id" {
#   type = string
# }

# variable "bastion_session_private_key_content" {
#   type = string
# }

variable "cluster_id" {
  type = string
}

variable "deploy_id" {
  type = string
}

variable "langfuse_helm_chart_version" {
  type    = string
  default = "1.5.3"
}

variable "defined_tags" {
  type    = any
  default = null
}

variable "devops_project_id" {
  type = string
}

variable "devops_environment_id" {
  type = string
}

variable "force_deployment" {
  type    = bool
  default = false
}

variable "oci_profile" {
  type    = string
  default = null
}