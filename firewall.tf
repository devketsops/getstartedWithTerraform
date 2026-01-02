# 1. Control Plane Firewall (Applied to the Master Node)
resource "digitalocean_firewall" "control_plane" {
  name        = "control-plane-firewall"
  
  # Links to the control_plane droplet defined in main.tf
  droplet_ids = [digitalocean_droplet.control_plane.id]

  # SSH Access: Restricted to your management range
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["196.3.49.0/24"]
  }

  # etcd server client API: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "2379-2380"
    source_addresses = ["10.122.0.0/20"]
  }

  # Kubernetes API server: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = ["10.122.0.0/20"]
  }

  # Kubelet API, Kube-scheduler, Kube-controller-manager: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "10248-10260"
    source_addresses = ["10.122.0.0/20"]
  }

  # Standard Outbound Rules (Allow all IPv4 and IPv6)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 2. Node Firewall (Applied to all Worker Nodes)
resource "digitalocean_firewall" "node" {
  name        = "node-firewall"
  
  # Links to all worker droplets created with 'count' in main.tf
  droplet_ids = digitalocean_droplet.nodes.*.id

  # SSH Access: Restricted to your management range
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["196.3.49.0/24"]
  }

  # Kubelet API: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "10250"
    source_addresses = ["10.122.0.0/20"]
  }

  # Kube-proxy: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "10256"
    source_addresses = ["10.122.0.0/20"]
  }

  # NodePort Services: Internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "30000-32767"
    source_addresses = ["10.122.0.0/20"]
  }

  # Standard Outbound Rules (Allow all IPv4 and IPv6)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}