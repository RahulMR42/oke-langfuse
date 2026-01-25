## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

module "istio_deployment_using_addon_manager" {
  # count                = local.enable_cert_manager ? (local.use_addon_manager ? 1 : 0) : 0
  source      = "./modules/oke_add_ons/istio/deployment/enhanced_cluster_addon"
  cluster_id  = oci_containerengine_cluster.oci_oke_cluster.id
  nb_replicas = 1
  depends_on = [
    oci_containerengine_cluster.oci_oke_cluster,
    oci_containerengine_node_pool.oci_oke_node_pool,
  ]
}

module "istio_gateway_class" {
  source                = "./modules/oke/istio_gateway_class"
  compartment_id        = local.devops_compartment_id
  cluster_id            = oci_containerengine_cluster.oci_oke_cluster.id
  devops_project_id     = module.devops_setup.project_id
  devops_environment_id = module.devops_target_cluster_env.environment_id
  subnet_id             = oci_containerengine_cluster.oci_oke_cluster.endpoint_config[0].subnet_id
  depends_on = [
    module.istio_deployment_using_addon_manager
  ]
}

# module "istio_workload_identity_policy" {
#   source               = "./modules/iam/workload_identity"
#   compartment_id       = var.cluster_compartment_id
#   workload_name        = "istio"
#   service_account_name = "istio"
#   namespace            = "istio-system"
#   permissions = [
#     "manage load-balancers",
#     "use virtual-network-family",
#     "manage cabundles",
#     "manage cabundle-associations",
#     "manage leaf-certificates",
#     "read leaf-certificate-bundles",
#     "manage leaf-certificate-versions",
#     "manage certificate-associations",
#     "read certificate-authorities",
#     "manage certificate-authority-associations",
#     "read certificate-authority-bundles",
#     "read public-ips",
#     "manage floating-ips",
#     "manage waf-family",
#     "read cluster-family",
#     "use tag-namespaces"
#   ]
#   defined_tags = var.defined_tags
#   cluster_id   = oci_containerengine_cluster.oci_oke_cluster.id
#   providers = {
#     oci = oci.home_region
#   }
#   depends_on = [
#     module.istio_deployment_using_addon_manager, # metrics server depends on cert-manager
#     oci_containerengine_node_pool.oci_oke_node_pool
#   ]
# }
