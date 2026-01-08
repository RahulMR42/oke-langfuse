## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

#  Create a load balancer via Ingress in Kubernetes
# TODO: look at using native ingress controller as nginx-ingress is being deprecated in March 2026
# https://cert-manager.io/announcements/2025/11/26/ingress-nginx-eol-and-gateway-api/


# module "nginx_ingress_controller" {
#   source                = "./modules/oke/nginx_ingress_controller"
#   compartment_id        = var.cluster_compartment_id
#   cluster_id            = oci_containerengine_cluster.oci_oke_cluster.id
#   devops_project_id     = module.devops_setup.project_id
#   devops_environment_id = module.devops_target_cluster_env.environment_id

#   depends_on = [
#     oci_containerengine_node_pool.oci_oke_node_pool
#   ]
# }


# module "nginx_ingress_workload_identity_policy" {
#   source               = "./modules/iam/workload_identity"
#   compartment_id       = var.cluster_compartment_id
#   workload_name        = "oci-native-ingress-controller"
#   service_account_name = "oci-native-ingress-controller"
#   namespace            = "native-ingress-controller-system"
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
#     module.cert_manager_deployment_using_addon_manager, # metrics server depends on cert-manager
#     oci_containerengine_node_pool.oci_oke_node_pool
#   ]
# }
