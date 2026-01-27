## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# build the Langfuse image
resource "null_resource" "deploy_oci_native_ingress_class" {
  triggers = {
    instance_id  = var.builder_details.instance_id
    manifest_sha = sha256(file("${path.module}/manifests/oci_native_ingress_class.yaml"))
    script_sha   = sha256(file("${path.module}/scripts/deploy_ingress_class.sh"))

  }
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = var.builder_details.private_key
    host        = var.builder_details.ip_address
  }

  provisioner "file" {
    source      = "${path.module}/manifests/oci_native_ingress_class.yaml"
    destination = "/home/opc/oci_native_ingress_class.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/deploy_ingress_class.sh"
    destination = "/home/opc/deploy_ingress_class.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/opc/deploy_ingress_class.sh",
      "/home/opc/deploy_ingress_class.sh",
    ]
  }
}
