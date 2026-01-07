## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  policy_statements = compact([
    for permission in var.permissions : "Allow any-user to ${permission} in compartment id ${var.compartment_id} ${var.use_nsg == true ? "where ALL {request.networkSource.name='${var.nsg_name}'}" : "where ANY {request.principal.type='instance', request.principal.type='cluster'}"}"
  ])
}

output "policy_statements" {
  value = local.policy_statements
}

