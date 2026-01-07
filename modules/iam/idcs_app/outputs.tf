## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "details" {
  value = {
    app_id        = local.idcs_app_id
    domain_url    = local.idcs_domain_url
    client_id     = local.idcs_client_id
    client_secret = local.idcs_client_secret
  }
}
