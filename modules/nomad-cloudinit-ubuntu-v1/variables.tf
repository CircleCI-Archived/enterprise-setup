variable "server_private_ip" {
  description = "Private ip of the nomad server, usually the services box"
  default     = ""
}

variable "http_proxy" {
  description = ""
  default     = ""
}

variable "https_proxy" {
  description = ""
  default     = ""
}

variable "no_proxy" {
  description = ""
  default     = ""
}

