resource "digitalocean_vpc" "kubernetes_vpc" {
  name     = "k8s-vpc"
  region   = "blr1"
  ip_range = "10.122.0.0/20"
}