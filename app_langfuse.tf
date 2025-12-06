
module "langfuse" {
  source                              = "./modules/apps/langfuse"
  compartment_id                      = var.cluster_compartment_id
  tenancy_ocid                        = var.tenancy_ocid
  region                              = var.region
  oci_profile = var.oci_profile
  cluster_id                          = oci_containerengine_cluster.oci_oke_cluster.id
  # bastion_session_id                  = oci_bastion_session.installer_session[0].id
  # bastion_session_private_key_content = tls_private_key.bastion_session_public_private_key_pair.private_key_openssh
  psql_host                           = data.oci_psql_db_system_connection_detail.psql_connection_detail.primary_db_endpoint[0].fqdn
  psql_cert                           = data.oci_psql_db_system_connection_detail.psql_connection_detail.ca_certificate
  psql_password                       = random_string.postgres_password.result
  s3_client_id                        = var.langfuse_s3_access_key
  s3_client_secret                    = var.langfuse_s3_secret_key
  idcs_client_id                      = data.oci_identity_domains_app.idcs_app.name
  idcs_client_secret                  = data.oci_identity_domains_app.idcs_app.client_secret
  idcs_app_id                         = var.idcs_app_id
  redis_hostname                      = oci_redis_redis_cluster.redis.primary_fqdn
  devops_project_id = module.devops_setup.project_id
  devops_environment_id = module.devops_target_cluster_env.environment_id
  deploy_id = local.deploy_id

  depends_on = [
    oci_containerengine_node_pool.oci_oke_node_pool,
    # local_file.kubeconfig,
    # oci_bastion_session.installer_session
  ]

}