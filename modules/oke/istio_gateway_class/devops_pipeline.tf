## Copyright © 2022-2026, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Shell stage deploy using a Command Spec to apply Gateway API CRDs-based resources
# This replaces the previous OKE manifest deployment which does not support CRDs reliably.

# resource "oci_artifacts_repository" "istio_gateway_class_manifest_repository" {
#   compartment_id  = var.compartment_id
#   display_name    = "istio_gateway_class_manifest_repo"
#   is_immutable    = false # Set to true if artifacts in this repository should be immutable
#   repository_type = "GENERIC"
# }

# resource "oci_generic_artifacts_content_artifact_by_path" "istio_gateway_class_manifest_artifact" {
#   #Required
#   artifact_path = "istio.GatewayClass.yaml"
#   repository_id = oci_artifacts_repository.istio_gateway_class_manifest_repository.id
#   version       = "0.1.0"
#   content       = file("${path.module}/manifests/istio.GatewayClass.yaml")

#   # delete the resource from artifact repo on destroy as it blocks destroy of the artifact repo itself
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-CMD
#       oci artifacts generic artifact delete --artifact-id ${self.id} --force
#     CMD
#   }

# }

# resource "oci_devops_deploy_artifact" "istio_gateway_class_manifest" {
#   argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
#   deploy_artifact_source {
#     #Required
#     deploy_artifact_source_type = "GENERIC_ARTIFACT"

#     #Optional
#     deploy_artifact_path    = "istio.GatewayClass.yaml"
#     deploy_artifact_version = "0.1.0"
#     repository_id           = oci_artifacts_repository.istio_gateway_class_manifest_repository.id
#   }
#   deploy_artifact_type = "KUBERNETES_MANIFEST"
#   description          = "Istio Gateway Class manifest"
#   display_name         = "istio-gateway-class-manifest"
#   defined_tags         = var.defined_tags
#   project_id           = var.devops_project_id
#   lifecycle {
#     ignore_changes = [defined_tags]
#   }
# }

resource "oci_devops_deploy_artifact" "istio_gateway_class_commandspec" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    # Inline Command Spec YAML
    base64encoded_content       = base64encode(file("${path.module}/manifests/command_spec.yaml"))
    deploy_artifact_source_type = "INLINE"
  }
  deploy_artifact_type = "DEPLOYMENT_SPEC"
  description          = "Langfuse GatewayClass shell stage command spec"
  display_name         = "istio-gateway-class-commandspec"
  defined_tags         = var.defined_tags
  project_id           = var.devops_project_id
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_devops_deploy_pipeline" "istio_gateway_class" {
  deploy_pipeline_parameters {
    items {
      name          = "CLUSTER_OCID"
      default_value = var.cluster_id
      description   = "The cluster OCID"
    }
    # items {
    #   name = "ARTIFACT_OCID"
    #   default_value = oci_generic_artifacts_content_artifact_by_path.istio_gateway_class_manifest_artifact.id
    #   description = "OCID of the artifact"
    # }
    # items {
    #   name = "REGISTRY_OCID"
    #   default_value = oci_artifacts_repository.istio_gateway_class_manifest_repository.id
    #   description = "OCID of the artifact repository"
    # }
  }
  description  = "Istio Gateway Class"
  display_name = "istio-gateway-class"
  project_id   = var.devops_project_id
  defined_tags = var.defined_tags
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_devops_deploy_stage" "istio_gateway_class" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.istio_gateway_class.id
  deploy_stage_predecessor_collection {
    items { id = oci_devops_deploy_pipeline.istio_gateway_class.id }
  }
  deploy_stage_type                 = "SHELL"
  description                       = "Deploy Gateway (Shell stage)"
  display_name                      = "istio-gateway-class-shell"
  defined_tags                      = var.defined_tags
  command_spec_deploy_artifact_id   = oci_devops_deploy_artifact.istio_gateway_class_commandspec.id
  oke_cluster_deploy_environment_id = var.devops_environment_id

  container_config {
    #Required
    container_config_type = "CONTAINER_INSTANCE_CONFIG"
    network_channel {
      #Required
      network_channel_type = "SERVICE_VNIC_CHANNEL"
      subnet_id            = var.subnet_id

      #Optional
      nsg_ids = []
    }
    shape_config {
      #Required
      ocpus = 2

      #Optional
      memory_in_gbs = 8
    }
    shape_name     = "CI.Standard.E4.Flex"
    compartment_id = var.compartment_id
  }


  rollback_policy { policy_type = "NO_STAGE_ROLLBACK_POLICY" }
  lifecycle { ignore_changes = [defined_tags] }



}

resource "oci_devops_deployment" "istio_gateway_class_deployment" {
  deploy_pipeline_id            = oci_devops_deploy_pipeline.istio_gateway_class.id
  deployment_type               = "PIPELINE_DEPLOYMENT"
  display_name                  = "istio-gateway-class"
  defined_tags                  = var.defined_tags
  trigger_new_devops_deployment = "false"
  depends_on = [
    oci_devops_deploy_stage.istio_gateway_class,
    oci_devops_deploy_artifact.istio_gateway_class_commandspec
  ]
  lifecycle { ignore_changes = [defined_tags] }
}
