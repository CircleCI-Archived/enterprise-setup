data "template_file" "nomad_user_data" {
  template = file("${path.module}/templates/nomad_user_data.tpl")

  vars = {
    nomad_server = var.server_private_ip
    http_proxy   = var.http_proxy
    https_proxy  = var.https_proxy
    no_proxy     = var.no_proxy
  }
}

