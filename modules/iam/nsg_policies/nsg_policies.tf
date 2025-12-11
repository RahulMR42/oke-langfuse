locals {
  policy_statements = compact([
    for permission in var.permissions : "Allow any-user to ${permission} in compartment id ${var.compartment_id} ${var.use_nsg == true ? "where ALL {request.networkSource.name='${var.nsg_name}'}" : "where ANY {request.principal.type='instance', request.principal.type='cluster'}"}"
  ])
}

output "policy_statements" {
  value = local.policy_statements
}

