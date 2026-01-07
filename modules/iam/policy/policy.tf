## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_policy" "policy" {
  #Required
  compartment_id = var.compartment_id
  description    = var.description
  name           = lower(replace(var.description, " ", "_"))
  statements     = var.policy_statements
}
