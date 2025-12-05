resource "oci_core_instance" "langfuse_builder" {
    #Required
    availability_domain = local.ADs[0]
    compartment_id = var.cluster_compartment_id
    shape = local.node_pools[0].node_shape

    create_vnic_details {

        #Optional
        assign_ipv6ip = false
        assign_public_ip = true
        display_name = "${local.cluster_name_sanitized}-builder"
        
        subnet_id = var.use_existing_vcn ? var.public_lb_subnet : oci_core_subnet.oke_lb_subnet[0].id
    }
    display_name = "${local.cluster_name_sanitized}-builder"
    extended_metadata = {
        deploy_id = local.deploy_id
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
        source_id = local.node_pools[0].image_id
        source_type = "image"

        #Optional
        boot_volume_size_in_gbs = 100
        boot_volume_vpus_per_gb = 10
    }
    preserve_boot_volume = false
}

## TODO policy for this builder instance
module "builder_policy" {
    source = "./modules/iam/policy"
    compartment_id = var.cluster_compartment_id
    description = "policy for ${local.deploy_id} builder"
    policy_statements = [
        "allow any-user to manage repos in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
        "allow any-user to manage instance-family in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
        "allow any-user to manage cluster-family in compartment id ${var.cluster_compartment_id} where ALL { request.principal.id = '${oci_core_instance.langfuse_builder.id}' }",
    ]
}


resource "null_resource" "builder_run" {
    triggers = {
        instance_id = oci_core_instance.langfuse_builder.id
        script_sha = sha256(file("./scripts/build_images.sh"))
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
    depends_on = [ module.builder_policy ]
}

resource "random_string" "oci_genai_gateway_default_api_key" {
    length      = 20
    special     = false
    min_lower   = 2
    min_upper   = 2
    min_numeric = 4
}

resource "null_resource" "create_secrets" {
    triggers = {
        instance_id = oci_core_instance.langfuse_builder.id
    }
    connection {
        type        = "ssh"
        user        = "opc"
        private_key = tls_private_key.bastion_session_public_private_key_pair.private_key_openssh
        host        = oci_core_instance.langfuse_builder.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "kubectl create secret generic oci-genai-gateway -n langfuse --from-literal=\"default_api_key\"=\"${random_string.oci_genai_gateway_default_api_key.result}\""
        ]
    }
    depends_on = [ 
        null_resource.builder_run, 
        oci_containerengine_node_pool.oci_oke_node_pool,
    ]
}
