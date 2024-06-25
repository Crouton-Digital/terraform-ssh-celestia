variable "ssh_host_ip" {}
variable "ssh_host_port" {}
variable "ssh_host_user" {}
variable "ssh_host_private_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "go_version" {}
variable "app_version" {}
variable "node_version" {}
variable "node_type" {}
variable "RPC_NODE_IP" {
  default = "https://celestia-testnet-rpc.crouton.digital"
}

variable "KEY_NAME" {
  default = "my_celes_key"
}
variable "CORE_IP" {}
variable "CORE_RPC_PORT" {}
variable "CORE_GRPC_PORT" {}

locals {

  install_update_packages =<<EOT
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu aria2 jq lz4 unzip -y
EOT

install_go =<<EOT
cd ~
! [ -x "$(command -v go)" ] && {
  VER="${var.go_version}"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
. ~/.bash_profile
go version
EOT

install_app = <<EOT
. ~/.bash_profile
cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app
git checkout tags/${ var.app_version } -b ${ var.app_version }
make install

cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/${ var.node_version }
make build
sudo make install
make cel-key

EOT


  init_bridge = <<EOT
. ~/.bash_profile
celestia bridge init --core.ip https://celestia-testnet-rpc.crouton.digital --p2p.network mocha

cd $HOME/celestia-node
./cel-key list --node.type bridge --keyring-backend test --p2p.network mocha > ~/bridge_adress_info


CORE_IP="${var.CORE_IP}"
CORE_RPC_PORT="${var.CORE_RPC_PORT}"
CORE_GRPC_PORT="${var.CORE_GRPC_PORT}"
KEY_NAME="${var.KEY_NAME}"

sudo tee /etc/systemd/system/celestia-bridge.service > /dev/null <<EOF
[Unit]
Description=celestia Bridge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) bridge start \
--core.ip $CORE_IP \
--core.rpc.port $CORE_RPC_PORT \
--core.grpc.port $CORE_GRPC_PORT \
--p2p.network mocha \
--keyring.accname $KEY_NAME \
--metrics.tls=true --metrics --metrics.endpoint otel.celestia-mocha.com
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-bridge
sudo systemctl restart celestia-bridge
# sudo journalctl -u celestia-bridge -f

EOT

snapshot_bridge = <<EOT

sudo tee /tmp/download_bridge_snapshot > /dev/null <<EOF
#!/bin/bash
cd $HOME
SNAP_NAME=$(curl -s https://server-8.itrocket.net/testnet/celestia/.current_state.json | jq -r '.SnapshotName')
aria2c -x 16 -s 16 -o celestia-bridge-snap.tar.lz4 https://server-8.itrocket.net/testnet/celestia/$SNAP_NAME
sudo systemctl stop celestia-bridge
rm -rf ~/.celestia-bridge-mocha-4/{blocks,data,index,inverted_index,transients,.lock}
tar -I lz4 -xvf ~/celestia-bridge-snap.tar.lz4 -C ~/.celestia-bridge-mocha-4/
sudo systemctl restart celestia-bridge
rm ~/celestia-bridge-snap.tar.lz4
EOF

chmod a+x /tmp/download_bridge_snapshot
/tmp/download_bridge_snapshot >> /tmp/snapshot.log 2>&1 &

EOT


  init_full = <<EOT
. ~/.bash_profile

cd ~/celestia-node
./cel-key add my_celes_key --keyring-backend test --node.type full --p2p.network mocha > ~/wallet_info

cd $HOME/celestia-node
./cel-key list --node.type full --keyring-backend test --p2p.network mocha > ~/fullnode_adress_info

celestia full init --keyring.accname my_celes_key --p2p.network mocha-4

CORE_IP="${var.CORE_IP}"
CORE_RPC_PORT="${var.CORE_RPC_PORT}"
CORE_GRPC_PORT="${var.CORE_GRPC_PORT}"
KEY_NAME="${var.KEY_NAME}"

sudo tee /etc/systemd/system/celestia-full.service > /dev/null <<EOF
[Unit]
Description=celestia full
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) full start \
--core.ip $CORE_IP \
--core.rpc.port $CORE_RPC_PORT \
--core.grpc.port $CORE_GRPC_PORT \
--p2p.network mocha \
--keyring.accname $KEY_NAME \
--metrics.tls=true --metrics --metrics.endpoint otel.celestia-mocha.com
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-full
sudo systemctl restart celestia-full

EOT




  info = <<EOT
Wallet info: cat ~/wallet_info

For read bridge logs: sudo journalctl -u celestia-bridge -f
For read full node logs: sudo journalctl -u celestia-full -f

You can find the address by running the following command:
  cd $HOME/celestia-node
  ./cel-key list --node.type bridge --keyring-backend test --p2p.network mocha

Get your node's peerId information:
  NODE_TYPE=bridge
  AUTH_TOKEN=$(celestia $NODE_TYPE auth admin --p2p.network mocha)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

Please wait download snapshot job use command:
  tail -f -n 50 /tmp/snapshot.log

EOT

}