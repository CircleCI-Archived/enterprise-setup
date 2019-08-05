data "template_file" "mod" {
  template = file("${path.module}/templates/builders_user_data.tpl")

  vars = {
    services_private_ip      = var.services_private_ip
    circle_secret_passphrase = var.circle_secret_passphrase
    http_proxy               = var.http_proxy
    https_proxy              = var.https_proxy
    no_proxy                 = var.no_proxy
  }
}

