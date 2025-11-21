#!/bin/bash
set -e

sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    socat \
    conntrack \
    ipset \
    qemu-kvm \
    libvirt-daemon-system \
    wireguard-tools

if [ ! -e /dev/kvm ]; then
    echo "ERROR: /dev/kvm not found"
    exit 1
fi

sudo modprobe vhost
sudo modprobe vhost_net
sudo modprobe vhost_vsock
sudo modprobe wireguard

cat <<EOF | sudo tee /etc/modules-load.d/vhost.conf
vhost
vhost_net
vhost_vsock
wireguard
EOF

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

if ! dpkg -l | grep -q "^ii.*containerd.io.*1.7.28"; then
    sudo apt-get install -y containerd.io=1.7.28-1~ubuntu.22.04~jammy
fi

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

KUBE_VERSION=$(apt-cache madison kubelet | grep "1.31" | head -1 | awk '{print $3}')
CURRENT_VERSION=$(dpkg -l kubelet 2>/dev/null | grep "^ii" | awk '{print $3}')

if [ "$CURRENT_VERSION" != "$KUBE_VERSION" ]; then
    sudo apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true
    sudo apt-get install -y \
      kubelet=${KUBE_VERSION} \
      kubeadm=${KUBE_VERSION} \
      kubectl=${KUBE_VERSION}
fi

sudo apt-mark hold kubelet kubeadm kubectl

if [ ! -f /opt/kata/bin/kata-runtime ]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh) -o"
    if [ -d ~/opt/kata ] && [ ! -d /opt/kata ]; then
        sudo mv ~/opt/kata /opt/
    fi
fi

if [ ! -f /etc/profile.d/kata.sh ]; then
    echo 'export PATH=$PATH:/opt/kata/bin' | sudo tee /etc/profile.d/kata.sh
fi
export PATH=$PATH:/opt/kata/bin

sudo ln -sf /opt/kata/bin/containerd-shim-kata-v2 /usr/local/bin/containerd-shim-kata-v2

if ! grep -q "use_vsock" /opt/kata/share/defaults/kata-containers/configuration-qemu.toml; then
    sudo sed -i 's/enable_annotations = \["enable_iommu", "virtio_fs_extra_args", "kernel_params"\]/enable_annotations = ["enable_iommu", "virtio_fs_extra_args", "kernel_params", "use_vsock"]/' /opt/kata/share/defaults/kata-containers/configuration-qemu.toml
fi

if ! grep -q "io.containerd.kata.v2" /etc/containerd/config.toml; then
    sudo bash -c 'cat >> /etc/containerd/config.toml << EOF

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  privileged_without_host_devices = true
  pod_annotations = ["io.katacontainers.*"]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
    ConfigPath = "/opt/kata/share/defaults/kata-containers/configuration.toml"
EOF'
fi

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl enable kubelet

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Setup completed"