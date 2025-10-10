data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Capacity check - verifies A1 Flex availability before deployment
data "external" "capacity_check" {
  count   = var.enable_capacity_check ? 1 : 0
  program = ["bash", "${path.module}/scripts/terraform-capacity-check.sh"]

  query = {
    region     = var.region
    ocpus      = tostring(var.coolify_ocpus)
    memory_gb  = tostring(var.coolify_memory_in_gbs)
    tenancy_id = var.tenancy_ocid
  }
}

locals {
  # When capacity check is enabled, use the AD with available capacity
  # Otherwise, use user-specified AD or first available
  capacity_check_ad = var.enable_capacity_check ? try(data.external.capacity_check[0].result.availability_domain, "") : ""
  fallback_ad       = var.availability_domain != "" ? var.availability_domain : try(data.oci_identity_availability_domains.ads.availability_domains[0].name, "")
  selected_ad       = trimspace(var.enable_capacity_check && local.capacity_check_ad != "" ? local.capacity_check_ad : local.fallback_ad)

  use_image_lookup = var.custom_image_ocid == ""
}

data "oci_core_images" "default" {
  count                    = local.use_image_lookup ? 1 : 0
  compartment_id           = oci_identity_compartment.vibestack.id
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  resolved_image_id = local.use_image_lookup ? try(data.oci_core_images.default[0].images[0].id, "") : var.custom_image_ocid
}
