resource "null_resource" init_full {
  count = var.node_type == "full" ? 1 : 0

  triggers = {
    init_full = local.init_full
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.init_full ]
  }

  depends_on = [ null_resource.install_app, ]

}