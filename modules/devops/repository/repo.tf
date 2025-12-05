resource "oci_devops_repository" "repository" {
  #Required
  name            = var.name
  project_id      = var.project_id
  repository_type = "HOSTED"

  #Optional
  default_branch = "refs/heads/main"
  defined_tags   = var.defined_tags
  description    = var.description

  lifecycle {
    ignore_changes = [defined_tags]
  }
}