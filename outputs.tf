output "control_plane_public_ip" {
  description = "Public IP of control plane"
  value       = digitalocean_droplet.control_plane.ipv4_address
}

output "control_plane_private_ip" {
  description = "Private IP of control plane"
  value       = digitalocean_droplet.control_plane.ipv4_address_private
}

output "worker_node_public_ips" {
  description = "Public IPs of worker nodes"
  value       = digitalocean_droplet.nodes[*].ipv4_address
}

output "worker_node_private_ips" {
  description = "Private IPs of worker nodes"
  value       = digitalocean_droplet.nodes[*].ipv4_address_private
}

output "ssh_control_plane" {
  description = "SSH command for control plane"
  value       = "ssh root@${digitalocean_droplet.control_plane.ipv4_address}"
}

output "ssh_nodes" {
  description = "SSH commands for worker nodes"
  value       = [for node in digitalocean_droplet.nodes : "ssh root@${node.ipv4_address}"]
}
