module "celestia-node" {
  source          = "../../"
#  source         = "Crouton-Digital/celestia/ssh"
#  version        = "0.0.2" # Set last module version

  ssh_host_ip   = "95.217.177.***"
  ssh_host_port = "22"
  ssh_host_user = "root"
  ssh_host_private_key_file = "~/.ssh/id_rsa"

  go_version       = "1.21.1"
  app_version      = "v1.9.0"
  node_version     = "v0.13.7"
  node_type        = "full" # bridge | full

  CORE_IP          = "65.109.93.124"
  CORE_RPC_PORT    = "28657"
  CORE_GRPC_PORT   = "28690"


}

output "info" {
  value = module.celestia-node.info
}