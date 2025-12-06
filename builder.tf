resource "oci_core_instance" "langfuse_builder" {
  #Required
  availability_domain = local.ADs[0]
  compartment_id      = var.cluster_compartment_id
  shape               = local.node_pools[0].node_shape

  create_vnic_details {

    #Optional
    assign_ipv6ip    = false
    assign_public_ip = true
    display_name     = "${local.cluster_name_sanitized}-builder"

    subnet_id = var.use_existing_vcn ? var.public_lb_subnet : oci_core_subnet.oke_lb_subnet[0].id
  }
  display_name = "${local.cluster_name_sanitized}-builder"
  extended_metadata = {
    deploy_id  = local.deploy_id
    cluster_id = oci_containerengine_cluster.oci_oke_cluster.id
  }
  metadata = {
    "ssh_authorized_keys" = "${var.ssh_public_key}\n${tls_private_key.bastion_session_public_private_key_pair.public_key_openssh}"
  }
  dynamic "shape_config" {
    for_each = length(regexall("Flex", local.node_pools[0]["node_shape"])) > 0 ? [1] : []
    content {
      ocpus         = 4
      memory_in_gbs = 24
    }
  }
  source_details {
    #Required
    source_id   = local.node_pools[0].image_id
    source_type = "image"

    #Optional
    boot_volume_size_in_gbs = 100
    boot_volume_vpus_per_gb = 10
  }
  preserve_boot_volume = false
}

## TODO policy for this builder instance
module "builder_policy" {
  source         = "./modules/iam/policy"
  compartment_id = var.cluster_compartment_id
  description    = "policy for ${local.deploy_id} builder"
  policy_statements = [
    "allow any-user to manage repos in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
    "allow any-user to manage instance-family in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
    "allow any-user to manage cluster-family in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
  ]
}


resource "null_resource" "builder_run" {
  triggers = {
    instance_id = oci_core_instance.langfuse_builder.id
    script_sha  = sha256(file("./scripts/build_images.sh"))
  }
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = tls_private_key.bastion_session_public_private_key_pair.private_key_openssh
    host        = oci_core_instance.langfuse_builder.public_ip
  }

  provisioner "file" {
    source      = "./scripts/build_images.sh"
    destination = "/home/opc/build_images.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/opc/build_images.sh",
      "/home/opc/build_images.sh",
    ]
  }
  depends_on = [module.builder_policy]
}

resource "random_string" "oci_genai_gateway_default_api_key" {
  length      = 20
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

resource "null_resource" "create_oci_genai_gateway_secrets" {
  triggers = {
    instance_id = oci_core_instance.langfuse_builder.id
    script      = file("./scripts/create_oci_genai_gateway_secrets.sh")
    default_api_keys = random_string.oci_genai_gateway_default_api_key.result
  }
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = tls_private_key.bastion_session_public_private_key_pair.private_key_openssh
    host        = oci_core_instance.langfuse_builder.public_ip
  }

  provisioner "remote-exec" {
    # wrap the inline script into a template script file so the file content can be used as a trigger 
    # and this runs each time the script changes
    inline = [<<EOF
            ${templatefile("./scripts/create_oci_genai_gateway_secrets.sh", {
      default_api_keys = random_string.oci_genai_gateway_default_api_key.result
})}
        EOF
]
# inline = [<<EOF
#     # oci-genai-gateway default API key value
#     kubectl get secret oci-genai-gateway -n langfuse \
#     && kubectl delete secret oci-genai-gateway -n langfuse

#     kubectl create secret generic oci-genai-gateway \
#     --namespace langfuse \
#     --from-literal="DEFAULT_API_KEYS"="${random_string.oci_genai_gateway_default_api_key.result}"
#     EOF
# ]
}
depends_on = [
  null_resource.builder_run,
  oci_containerengine_node_pool.oci_oke_node_pool,
]
}

# Langfuse 

resource "random_string" "langfuse_password_encryption_key" {
  length      = 64
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

resource "random_string" "langfuse_password_encryption_salt" {
  length      = 24
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

resource "random_string" "langfuse_next_auth_secret" {
  length      = 48
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

resource "random_string" "langfuse_clickhouse_password" {
  length      = 24
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

resource "random_string" "langfuse_redis_password" {
  length      = 24
  special     = false
  min_lower   = 2
  min_upper   = 2
  min_numeric = 4
}

# creates secrets for langfuse. We don't want these coded into a manifest stored in artifacts, 
# or passing secrets as ENV variables to a build step
# so this ensures secrets are created without leaving the 
resource "null_resource" "create_langfuse_secrets" {
  triggers = {
    instance_id = oci_core_instance.langfuse_builder.id
    script      = file("./scripts/create_langfuse_secrets.sh")
    encryption_key      = random_string.langfuse_password_encryption_key.result
    salt                = random_string.langfuse_password_encryption_salt.result
    nextauth_secret     = random_string.langfuse_next_auth_secret.result
    clickhouse_password = random_string.langfuse_clickhouse_password.result
    redis_password      = random_string.langfuse_redis_password.result
    postgres_password   = random_string.postgres_password.result
  }
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = tls_private_key.bastion_session_public_private_key_pair.private_key_openssh
    host        = oci_core_instance.langfuse_builder.public_ip
  }

  provisioner "file" {
    source      = "CaCertificate-langfuse.pub"
    destination = "/home/opc/CaCertificate-langfuse.pub"
  }

  provisioner "remote-exec" {
    when = create
    # wrap the inline script into a template script file so the file content can be used as a trigger 
    # and this runs each time the script changes
    inline = [
      <<EOF
            ${templatefile("./scripts/create_langfuse_secrets.sh", {
      encryption_key      = random_string.langfuse_password_encryption_key.result
      salt                = random_string.langfuse_password_encryption_salt.result
      nextauth_secret     = random_string.langfuse_next_auth_secret.result
      clickhouse_password = random_string.langfuse_clickhouse_password.result
      redis_password      = random_string.langfuse_redis_password.result
      client_id           = local.idcs_client_id
      client_secret       = local.idcs_client_secret
      issuer              = local.idcs_domain_url
      s3_access_key       = var.langfuse_s3_access_key
      s3_secret_key       = var.langfuse_s3_secret_key
      postgres_password   = random_string.postgres_password.result
      database_url        = "postgresql://langfuse:${random_string.postgres_password.result}@${local.psql_endpoint.fqdn}:${local.psql_endpoint.port}/postgres?sslmode=verify-full&sslrootcert=/secrets/db-keystore/CaCertificate-langfuse.pub"
})}
        EOF
]
# inline = [<<EOF
#     #!/bin/bash
#     set -e -o pipefail

#     # langfuse password hashing
#     kubectl get secret langfuse -n langfuse \
#     && kubectl delete secret langfuse -n langfuse

#     kubectl create secret generic langfuse \
#         --namespace langfuse \
#         --from-literal="encryption-key"="${random_string.langfuse_password_encryption_key.result}" \
#         --from-literal="salt"="${random_string.langfuse_password_encryption_salt.result}" \
#         --from-literal="nextauth-secret"="${random_string.langfuse_next_auth_secret.result}" \
#         --from-literal="clickhouse-password"="${random_string.langfuse_clickhouse_password.result}" \
#         --from-literal="redis-password"="${random_string.langfuse_redis_password.result}"

#     # langfuse IDCS secrets
#     kubectl get secret langfuse-idcs -n langfuse \
#     && kubectl delete secret langfuse-idcs -n langfuse

#     kubectl create secret generic langfuse-idcs \
#         --namespace langfuse \
#         --from-literal="client-id"="${local.idcs_client_id}" \
#         --from-literal="client-secret"="${local.idcs_client_secret}" \
#         --from-literal="issuer"="${local.idcs_domain_url}" \
#         --from-literal="name"="Oracle IDCS"

#     # Langfuse Object Storage access keys
#     kubectl get secret langfuse-s3 -n langfuse \
#     && kubectl delete secret langfuse-s3 -n langfuse

#     kubectl create secret generic langfuse-s3 \
#         --namespace langfuse \
#         --from-literal="s3-access-key"="${var.langfuse_s3_access_key}" \
#         --from-literal="s3-secret-key"="${var.langfuse_s3_secret_key}"

#     # langfuse Postgres cert
#     kubectl get secret langfuse-postgres-cert -n langfuse \
#     && kubectl delete secret langfuse-postgres-cert -n langfuse

#     kubectl create secret generic langfuse-postgres-cert \
#         --namespace langfuse \
#         --from-file=CaCertificate-langfuse.pub

#     rm -f CaCertificate-langfuse.pub

#     # langfuse postgres password and connection string
#     kubectl get secret langfuse-postgres -n langfuse \
#     && kubectl delete secret langfuse-postgres -n langfuse

#     kubectl create secret generic langfuse-postgres \
#         --namespace langfuse \
#         --from-literal="postgres-password"="${random_string.postgres_password.result}" \
#         --from-literal="database-url"="postgresql://langfuse:${random_string.postgres_password.result}@${local.psql_endpoint.fqdn}:${local.psql_endpoint.port}/postgres?sslmode=verify-full&sslrootcert=/secrets/db-keystore/CaCertificate-langfuse.pub"

#     EOF
# ]
}


depends_on = [
  null_resource.builder_run,
  oci_containerengine_node_pool.oci_oke_node_pool,
]
}