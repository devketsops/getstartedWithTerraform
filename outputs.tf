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

output "worker_node_names" {
  description = "Names of worker nodes"
  value       = digitalocean_droplet.nodes[*].ipv4_address
}

output "get_kubeconfig_command" {
  description = "Command to copy kubeconfig locally"
  value       = "scp root@${digitalocean_droplet.control_plane.ipv4_address}:/root/.kube/config ~/.kube/config-do-cluster"
}

output "verify_cluster_command" {
  description = "Command to verify cluster is ready"
  value       = "ssh root@${digitalocean_droplet.control_plane.ipv4_address} 'kubectl get nodes'"
}

output "verify_calico_command" {
  description = "Command to verify Calico installation"
  value       = "ssh root@${digitalocean_droplet.control_plane.ipv4_address} 'kubectl get pods -n calico-system'"
}
