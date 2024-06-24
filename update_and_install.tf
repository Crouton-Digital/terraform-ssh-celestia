# Install Update
resource "null_resource" "update_system" {

  triggers = {
    update_packages = local.install_update_packages
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_update_packages ]
  }

  depends_on = []
}

# Install GO
resource "null_resource" "install_go" {

  triggers = {
    install_go = local.install_go
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_go ]
  }

  depends_on = [ null_resource.update_system, ]

}

# Install APP node project
resource "null_resource" "install_app" {

  triggers = {
    install_app = local.install_app
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_app ]
  }

  depends_on = [ null_resource.install_go, ]

}











