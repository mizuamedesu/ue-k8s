#!/bin/bash
set -e

sudo apt-get update
sudo apt-get upgrade -y

echo "[2/10] Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg socat conntrack ipset

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

cat <<INNER_EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
wireguard
INNER_EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe wireguard

cat <<INNER_EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
INNER_EOF

sudo sysctl --system

sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

sudo apt-get install -y wireguard-tools

cat <<INNER_EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
INNER_EOF

echo "Installing Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install -y tailscale

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Installed versions:"
kubeadm version
kubelet --version
kubectl version --client
containerd --version
wg version