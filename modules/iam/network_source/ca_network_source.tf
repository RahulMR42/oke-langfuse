## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_network_source" "network_source" {
  #Required
  compartment_id = var.tenancy_ocid
  description    = var.nsg_name
  name           = var.nsg_name

  virtual_source_list {
    vcn_id    = var.vcn_id
    ip_ranges = var.subnets_cidrs
  }
}
