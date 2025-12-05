output "content" {
  value = base64encode(templatefile("${path.module}/cloud-init.tmpl.yaml", {
    base64_encoded_docker_login_script            = base64encode(file("${path.module}/scripts/docker_login.sh"))
    base64_encoded_docker_cred_init_helper_script = base64encode(file("${path.module}/scripts/docker-credential-helper-init.sh"))
  }))
}


# data "cloudinit_config" "cloud-init" {
#   gzip          = false
#   base64_encode = true

#   part {
#     filename     = "oke-init.sh"
#     content_type = "text/x-shellscript"

#     content = file("${path.module}/scripts/oke-init.sh")
#   }

#   part {
#     filename     = "cloud-config.yaml"
#     content_type = "text/cloud-config"

#     content = templatefile("${path.module}/scripts/cloud-config.tmpl.yaml", {
#         base64_encoded_docker_login_script            = base64encode(file("${path.module}/scripts/docker_login.sh"))
#         base64_encoded_docker_cred_init_helper_script = base64encode(file("${path.module}/scripts/docker-credential-helper-init.sh"))
#     })
#   }
# }

# output "content" {
#   value = data.cloudinit_config.cloud-init.rendered
# }