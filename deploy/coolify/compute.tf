# =============================================================================
# PRE-DEPLOYMENT VALIDATION
# =============================================================================
# Validate deployment configuration before creating any resources

resource "null_resource" "validate_deployment" {
  lifecycle {
    precondition {
      condition     = var.deploy_coolify || var.deploy_kasm
      error_message = "At least one of deploy_coolify or deploy_kasm must be true. For this Coolify-only package, deploy_coolify should be true."
    }

    precondition {
      condition     = (var.deploy_coolify ? var.coolify_ocpus : 0) <= 4
      error_message = "Total OCPUs (${var.deploy_coolify ? var.coolify_ocpus : 0}) exceeds Always Free limit of 4."
    }

    precondition {
      condition     = (var.deploy_coolify ? var.coolify_memory_in_gbs : 0) <= 24
      error_message = "Total memory (${var.deploy_coolify ? var.coolify_memory_in_gbs : 0}GB) exceeds Always Free limit of 24GB."
    }
  }
}

# =============================================================================
# COOLIFY COMPUTE INSTANCE
# =============================================================================

resource "oci_core_instance" "coolify" {
  count               = var.deploy_coolify ? 1 : 0
  availability_domain = local.selected_ad
  compartment_id      = oci_identity_compartment.vibestack.id
  display_name        = local.coolify_display_name
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_shape ? [1] : []
    content {
      ocpus         = var.coolify_ocpus
      memory_in_gbs = var.coolify_memory_in_gbs
    }
  }

  create_vnic_details {
    assign_public_ip = var.assign_public_ip
    hostname_label   = local.coolify_hostname
    subnet_id        = oci_core_subnet.public.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    user_data = base64encode(templatefile("${path.module}/cloud-init-coolify.yaml", {
      ssh_authorized_keys    = var.ssh_authorized_keys
      cloudflare_env_vars    = local.cloudflare_env_vars
      setup_custom_ssl       = local.setup_custom_ssl
      ssl_cert_b64           = local.ssl_cert_b64
      ssl_key_b64            = local.ssl_key_b64
      ssl_chain_b64          = local.ssl_chain_b64
      skip_ansible_execution = var.skip_ansible_execution
      coolify_root_username  = local.coolify_root_username
      coolify_root_email     = local.coolify_root_email
      coolify_root_password  = local.coolify_root_password
    }))
  }

  source_details {
    source_type = "image"
    source_id   = local.resolved_image_id
  }

  lifecycle {
    precondition {
      condition     = local.selected_ad != ""
      error_message = "Unable to determine an availability domain. Provide availability_domain explicitly."
    }

    precondition {
      condition     = local.resolved_image_id != ""
      error_message = "Unable to resolve a compute image. Specify custom_image_ocid to proceed."
    }

    precondition {
      condition     = !var.enable_capacity_check || try(data.external.capacity_check[0].result.available, "false") == "true"
      error_message = <<-EOT
        No A1 Flex capacity available in region ${var.region} for ${var.coolify_ocpus} OCPUs and ${var.coolify_memory_in_gbs}GB RAM.

        Options:
        1. Try again later (capacity changes frequently)
        2. Try a different region
        3. Try a smaller configuration (2 OCPUs, 12GB RAM)
        4. Use the monitoring script for automated retry:
           Extract the deployment package and run:
           ./scripts/monitor-and-deploy.sh --stack-id <YOUR_STACK_OCID>
        5. Disable capacity checking by unchecking "Check capacity before deployment"
      EOT
    }
  }
}
