variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "pvt_key" {
  description = "Path to SSH private key for droplet access"
  type        = string
}
