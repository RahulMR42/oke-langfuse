## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      # configuration_aliases = [oci.home_region]
    }
  }
}

