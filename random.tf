resource "random_string" "random_suffix" {
  length  = 5
  upper   = false
  lower   = true
  number  = false
  special = false
}
