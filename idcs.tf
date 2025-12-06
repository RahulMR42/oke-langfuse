
data "oci_identity_domains_app" "idcs_app" {
  #Required
  app_id        = var.idcs_app_id
  idcs_endpoint = var.idcs_domain_url
}

output "idcs" {
  value = data.oci_identity_domains_app.idcs_app
}

locals {
  idcs_domain_url    = var.idcs_domain_url
  idcs_client_id     = data.oci_identity_domains_app.idcs_app.name
  idcs_client_secret = data.oci_identity_domains_app.idcs_app.client_secret
}