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

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key)
    host        = self.ipv4_address
  }

  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  # Initialize the control plane
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to stabilize...'",
      "sleep 30",
      "echo 'Initializing Kubernetes control plane...'",
      "kubeadm init --apiserver-advertise-address=${self.ipv4_address_private} --apiserver-cert-extra-sans=${self.ipv4_address_private} --pod-network-cidr=192.168.0.0/16 --node-name control-plane --ignore-preflight-errors Swap > /tmp/kubeadm-init.log 2>&1",
      "echo 'Setting up kubectl configuration...'",
      "mkdir -p /root/.kube",
      "cp -i /etc/kubernetes/admin.conf /root/.kube/config",
      "chown $(id -u):$(id -g) /root/.kube/config"
    ]
  }

  # Install Calico CNI
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing Calico CNI...'",
      "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml",
      "sleep 10",
      "curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml -O",
      "kubectl apply -f custom-resources.yaml",
      "echo 'Waiting for Calico to be ready...'",
      "kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=300s || echo 'Calico installation initiated'"
    ]
  }

  # Generate and save the join command
  provisioner "remote-exec" {
    inline = [
      "echo 'Generating join command for worker nodes...'",
      "kubeadm token create --print-join-command > /tmp/join-command.sh",
      "chmod +x /tmp/join-command.sh"
    ]
  }
}

# 3. Fetch the join command from control plane
resource "null_resource" "get_join_command" {
  depends_on = [digitalocean_droplet.control_plane]

  triggers = {
    control_plane_id = digitalocean_droplet.control_plane.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key)
    host        = digitalocean_droplet.control_plane.ipv4_address
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ${var.pvt_key} root@${digitalocean_droplet.control_plane.ipv4_address} 'cat /tmp/join-command.sh' > ${path.module}/join-command.sh"
  }
}

# 4. Node Droplets (Worker Nodes)
resource "digitalocean_droplet" "nodes" {
  count      = 2
  image      = "ubuntu-24-04-x64"
  name       = "node-0${count.index + 1}"
  region     = "blr1"
  size       = "s-1vcpu-2gb" # 1 vCPU, 2GB RAM
  vpc_uuid   = digitalocean_vpc.kubernetes_vpc.id
  ssh_keys   = [data.digitalocean_ssh_key.k8s_key.id]
  user_data  = file("${path.module}/k8s_setup.sh")

  depends_on = [null_resource.get_join_command]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key)
    host        = self.ipv4_address
  }

  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  # Copy and execute join command
  provisioner "file" {
    source      = "${path.module}/join-command.sh"
    destination = "/tmp/join-command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to stabilize...'",
      "sleep 30",
      "echo 'Joining Kubernetes cluster...'",
      "chmod +x /tmp/join-command.sh",
      "bash /tmp/join-command.sh --ignore-preflight-errors Swap"
    ]
  }
}

# 5. Cleanup join command file on destroy
resource "null_resource" "cleanup_join_command" {
  depends_on = [digitalocean_droplet.nodes]

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/join-command.sh"
  }
}
