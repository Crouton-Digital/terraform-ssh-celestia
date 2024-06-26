# terraform-ssh-celestia
Deploy celestia node on VM


## Requirements to configure a celestia integration
The requirements to configure a celestia integration include:

* Suggested hardware requirements:
   * CPU: 8 physical cores / 16 vCPUs
   * RAM: 128 GB
   * Storage (SSD): 4 TB NVMe drive


## Deploy celestia-node


### Prepare terraform directory structure and deploy 

Example files you can take: 
```bash
git clone https://github.com/Crouton-Digital/terraform-ssh-celestia.git
cd terraform-ssh-celestia/examples/celestia-node
```

Example how to use module: 
```yaml
module "celestia-node" {
  source         = "Crouton-Digital/celestia/ssh"
  version        = "0.0.3" # Set last module version

  ssh_host_ip   = "***.***.***.***"
  ssh_host_port = "22"
  ssh_host_user = "root"
  ssh_host_private_key_file = "~/.ssh/id_rsa"

  go_version       = "1.21.1"
  app_version      = "v1.9.0"
  node_version     = "v0.13.7"
  node_type        = "bridge" # bridge | full | light

  CORE_IP          = "65.109.93.***"
  CORE_RPC_PORT    = "28657"
  CORE_GRPC_PORT   = "28690"
}

  output "info" {
  value = module.celestia-node.info
}
```

```bash
$ terraform init
$ terraform plan
$ terraform apply

$ terraform output 
```

### Manual restore snapshot for bridge node, when auto download is fail: 
```bash
cd $HOME
SNAP_NAME=$(curl -s https://server-8.itrocket.net/testnet/celestia/.current_state.json | jq -r '.SnapshotName')
aria2c -x 16 -s 16 -o celestia-bridge-snap.tar.lz4 https://server-8.itrocket.net/testnet/celestia/$SNAP_NAME
sudo systemctl stop celestia-bridge
rm -rf ~/.celestia-bridge-mocha-4/{blocks,data,index,inverted_index,transients,.lock}
tar -I lz4 -xvf ~/celestia-bridge-snap.tar.lz4 -C ~/.celestia-bridge-mocha-4/
sudo systemctl restart celestia-bridge && sudo journalctl -u celestia-bridge -f
```


Run `terraform destroy` when you don't need these resources.

https://crouton.digital/services/testnets/celestia