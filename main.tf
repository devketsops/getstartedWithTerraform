# 1. Reference the SSH Key existing in your DigitalOcean account
data "digitalocean_ssh_key" "k8s_key" {
  name = "Kets-Mac" 
}

# 2. Control-Plane Droplet (Control Plane Node)
resource "digitalocean_droplet" "control_plane" {
  image      = "ubuntu-24-04-x64"
  name       = "control-plane"
  region     = "blr1"
  size       = "s-2vcpu-2gb" # 2 vCPU, 2GB RAM
  vpc_uuid   = digitalocean_vpc.kubernetes_vpc.id
  ssh_keys   = [data.digitalocean_ssh_key.k8s_key.id]
  user_data  = file("${path.module}/k8s_setup.sh")
}

# 3. Node Droplets (Worker Nodes)
resource "digitalocean_droplet" "nodes" {
  count      = 2
  image      = "ubuntu-24-04-x64"
  name       = "node-0${count.index + 1}"
  region     = "blr1"
  size       = "s-1vcpu-2gb" # 1 vCPU, 2GB RAM
  vpc_uuid   = digitalocean_vpc.kubernetes_vpc.id
  ssh_keys   = [data.digitalocean_ssh_key.k8s_key.id]
  user_data  = file("${path.module}/k8s_setup.sh")
}
