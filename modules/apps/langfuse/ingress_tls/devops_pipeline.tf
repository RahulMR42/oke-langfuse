
# resource "oci_devops_deploy_artifact" "cluster_issuer_manifest_tls" {
#   argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
#   deploy_artifact_source {
#     base64encoded_content       = base64encode(file("${path.module}/manifests/letsencrypt.ClusterIssuer.yaml"))
#     deploy_artifact_source_type = "INLINE"
#   }
#   deploy_artifact_type = "KUBERNETES_MANIFEST"
#   description          = "LetsEncrypt Cluster Issuers manifest"
#   display_name         = "langfuse-cluster-issuers-manifest"
#   defined_tags         = var.defined_tags
#   project_id           = var.devops_project_id
#   lifecycle {
#     ignore_changes = [defined_tags]
#   }
# }

resource "oci_devops_deploy_artifact" "load_balancer_manifest_tls" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    base64encoded_content       = base64encode(file("${path.module}/manifests/langfuse_tls.Ingress.yaml"))
    deploy_artifact_source_type = "INLINE"
  }
  deploy_artifact_type = "KUBERNETES_MANIFEST"
  description          = "Langfuse TLS Ingress manifest"
  display_name         = "langfuse-tls-ingress-manifest"
  defined_tags         = var.defined_tags
  project_id           = var.devops_project_id
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_devops_deploy_pipeline" "ingress_tls" {
  deploy_pipeline_parameters {
    items {
      name = "LANGFUSE_HOSTNAME"
      default_value = var.langfuse_hostname
      description = "The hostname (IP) for the Langfuse instance"
    }
  }
  description  = "Langfuse Ingress"
  display_name = "langfuse-ingress-tls"
  project_id   = var.devops_project_id
  defined_tags = var.defined_tags
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

# resource "oci_devops_deploy_stage" "cluster_issuers" {
#   deploy_pipeline_id = oci_devops_deploy_pipeline.ingress_tls.id
#   deploy_stage_predecessor_collection {
#     items {
#       id = oci_devops_deploy_pipeline.ingress_tls.id
#     }
#   }
#   deploy_stage_type = "OKE_DEPLOYMENT"
#   description       = "Deploy Let's Encrypt Cluster Issuers"
#   display_name      = "cluster-issuers"
#   defined_tags      = var.defined_tags
#   kubernetes_manifest_deploy_artifact_ids = [
#     oci_devops_deploy_artifact.cluster_issuer_manifest_tls.id
#   ]
#   # namespace                         = "cert-manager"
#   oke_cluster_deploy_environment_id = var.devops_environment_id
#   rollback_policy {
#     policy_type = "AUTOMATED_STAGE_ROLLBACK_POLICY"
#   }
#   lifecycle {
#     ignore_changes = [defined_tags]
#   }
# }

resource "oci_devops_deploy_stage" "load_balancer_tls" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.ingress_tls.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.ingress_tls.id
      # id = oci_devops_deploy_stage.cluster_issuers.id
    }
  }
  deploy_stage_type = "OKE_DEPLOYMENT"
  description       = "Deploy Langfuse Ingress with TLS"
  display_name      = "langfuse-ingress-tls"
  defined_tags      = var.defined_tags
  kubernetes_manifest_deploy_artifact_ids = [
    oci_devops_deploy_artifact.load_balancer_manifest_tls.id
  ]
  namespace                         = "langfuse"
  oke_cluster_deploy_environment_id = var.devops_environment_id
  rollback_policy {
    policy_type = "AUTOMATED_STAGE_ROLLBACK_POLICY"
  }
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_devops_deployment" "ingress_lb_tls_deployment" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.ingress_tls.id
  deployment_type    = "PIPELINE_DEPLOYMENT"
  display_name       = "langfuse-ingress-tls"
  defined_tags       = var.defined_tags
  #previous_deployment_id = <<Optional value not found in discovery>>
  trigger_new_devops_deployment = tostring(var.force_deployment)
  depends_on = [
    # oci_devops_deploy_artifact.cluster_issuer_manifest_tls,
    # oci_devops_deploy_stage.cluster_issuers,
    oci_devops_deploy_stage.load_balancer_tls,
    oci_devops_deploy_artifact.load_balancer_manifest_tls
  ]
  lifecycle {
    ignore_changes = [defined_tags]
  }
}
