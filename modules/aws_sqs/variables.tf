variable "prefix" {}
variable "name" {}

# Recources tags
variable "tags" {
  type        = "map"
  description = "custom tags for services instance"
  default     = {}
}
