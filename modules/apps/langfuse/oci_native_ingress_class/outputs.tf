## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_load_balancer_load_balancers" "load_balancers" {
  #Required
  compartment_id = var.compartment_id

  #Optional
  detail = "full"
  display_name = "lb-${var.deploy_id}"

  depends_on = [null_resource.deploy_oci_native_ingress_class]
}


locals {
  lb = [for lb in data.oci_load_balancer_load_balancers.load_balancers.load_balancers : lb.ip_addresses[0]]
  #   if 
  #   # lb.defined_tags["Oracle-Tags.CreatedBy"] == var.cluster_id
  # lb.display_name == "lb-${var.deploy_id}"]
}

output "ip_address" {
  value = local.lb[0]
}
