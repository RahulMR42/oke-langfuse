## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "create_cluster_issuers" {
  triggers = {
    instance_id = var.builder_details.instance_id
    templ_sha   = sha256(file("${path.module}/scripts/letsencrypt.ClusterIssuer.yaml"))
  }
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = var.builder_details.private_key
    host        = var.builder_details.ip_address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/letsencrypt.ClusterIssuer.yaml"
    destination = "/home/opc/letsencrypt.ClusterIssuer.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f letsencrypt.ClusterIssuer.yaml"
    ]
  }
}
