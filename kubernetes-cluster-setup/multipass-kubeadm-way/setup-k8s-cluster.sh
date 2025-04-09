#!/bin/bash

set -e

echo "[1/5] 🚀 Launching Multipass VMs..."

multipass launch noble --name control-plane --cpus 2 -m 3G --disk 50G
multipass launch noble --name workera       --cpus 2 -m 3G --disk 50G
multipass launch noble --name workerb       --cpus 2 -m 3G --disk 50G

echo "[2/5] ⚙️ Setting up control-plane node..."

multipass shell control-plane <<'EOF'

# Disable swap
sudo swapoff -a

# Load br_netfilter
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf

# Set sysctl params
cat <<EOT | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sudo sysctl --system

# Install containerd
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes components
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.32.0.0/16

# Set up kubeconfig
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Cilium CNI
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar -xvzf cilium-linux-amd64.tar.gz -C /usr/local/bin
sudo chmod +x /usr/local/bin/cilium
rm cilium-linux-amd64.tar.gz
cilium install
cilium status

# Allow control-plane to run workloads
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

EOF

echo "[3/5] 📋 Retrieving kubeadm join command..."
JOIN_CMD=$(multipass exec control-plane -- sudo kubeadm token create --print-join-command)

echo "[4/5] 🤝 Setting up workera and joining the cluster..."

for NODE in workera workerb; do
  echo "➡️  Setting up $NODE..."
  multipass shell "$NODE" <<EOF

# Disable swap
sudo swapoff -a

# Load br_netfilter
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf

# Set sysctl params
cat <<EOT | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sudo sysctl --system

# Install containerd
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes components
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

# Join the cluster
sudo $JOIN_CMD

EOF
done

echo "[5/5] ✅ Cluster setup complete!"

# Optionally, get all nodes
multipass exec control-plane -- kubectl get nodes
