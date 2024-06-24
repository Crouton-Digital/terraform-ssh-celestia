resource "null_resource" init_bridge {
  count = var.node_type == "bridge" ? 1 : 0

  triggers = {
    init_bridge = local.init_bridge
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.init_bridge ]
  }

  depends_on = [ null_resource.install_app, ]

}

resource "null_resource" snapshot_bridge {
  count = var.node_type == "bridge" ? 1 : 0

  triggers = {
    snapshot_bridge = local.snapshot_bridge
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.snapshot_bridge ]
  }

  depends_on = [ null_resource.init_bridge, ]

}

#data "remote_file" "bridge_adress_info" {
#  #count = var.node_type == "bridge" ? 1 : 0
#
#  conn {
#    user           = var.ssh_host_user
#    private_key    = file(var.ssh_host_private_key_file)
#    host           = var.ssh_host_ip
#    port           = var.ssh_host_port
#    agent          = file(var.ssh_host_private_key_file) == null
#    sudo           = true
#  }
#  path = "~/bridge_adress_info"
#
#  depends_on = [ null_resource.init_bridge ]
#}
#
#output "bridge_adress_info" {
#  value = data.remote_file.bridge_adress_info.content
#}