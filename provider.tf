terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}
variable "pvt_key" {} # Ensure this matches the name used in main.tf

provider "digitalocean" {
  token = var.do_token
}