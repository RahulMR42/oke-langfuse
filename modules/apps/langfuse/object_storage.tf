locals {
  object_storage_bucket = "langfuse-${var.deploy_id}-traces"
}
resource "oci_objectstorage_bucket" "bucket" {
  #Required
  compartment_id = var.compartment_id
  name           = "langfuse-${var.deploy_id}-traces"
  namespace      = data.oci_objectstorage_namespace.ns.namespace

  #Optional
  auto_tiering          = "InfrequentAccess"
  object_events_enabled = "false"
  # retention_rules {
  #     display_name = var.retention_rule_display_name
  #     duration {
  #         #Required
  #         time_amount = var.retention_rule_duration_time_amount
  #         time_unit = var.retention_rule_duration_time_unit
  #     }
  #     time_rule_locked = var.retention_rule_time_rule_locked
  # }
  versioning = "Disabled"
}