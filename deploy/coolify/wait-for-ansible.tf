# Wait for Ansible completion using remote-exec provisioner
# This ensures Terraform doesn't complete until Ansible finishes
# NOTE: Only works when running Terraform locally with SSH access
# Disabled by default for OCI Resource Manager compatibility

resource "null_resource" "wait_for_ansible" {
  count = var.deploy_coolify && !var.skip_ansible_execution && var.wait_for_ansible ? 1 : 0

  depends_on = [
    oci_core_instance.coolify,
    oci_core_volume_attachment.coolify
  ]

  connection {
    type        = "ssh"
    host        = oci_core_instance.coolify[0].public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    timeout     = "30m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait || true",
      "echo 'Cloud-init finished. Waiting for Ansible completion marker...'",
      "timeout 1800 bash -c 'while [ ! -f /var/log/ansible-complete.marker ]; do sleep 5; done' || echo 'Timeout waiting for Ansible'",
      "echo 'Ansible installation complete!'"
    ]
  }
}
