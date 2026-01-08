## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  lb = [for lb in data.oci_load_balancer_load_balancers.load_balancers.load_balancers : lb.ip_addresses[0]
    if lb.defined_tags["Oracle-Tags.CreatedBy"] == var.cluster_id
  && lb.freeform_tags["source"] == "ingress-nginx-controller"]
}

output "ip_address" {
  value = local.lb[0]
}
