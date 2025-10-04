Currently situation:
1. deploy\coolify\cloud-init-coolify.yaml copies coolify-complete-setup.yml to /opt/vibestack/complete-setup.yml
2. Begins running /opt/vibestack/complete-setup.yml in Ansible
3. ends before ansible has completed. 

Investigate how to make the cloud-init WAIT until the Ansible installation is complete