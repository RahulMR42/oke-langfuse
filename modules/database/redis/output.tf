## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "details" {
  value = {
    hostname = oci_redis_redis_cluster.redis.primary_fqdn
    password = random_string.redis_password.result
  }
}
