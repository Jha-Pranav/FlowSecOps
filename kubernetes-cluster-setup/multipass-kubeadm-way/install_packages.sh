# !/bin/bash
# 1. Remove Swap memmory
swapoff -a

# 2. Setup Required Sysctl Params
echo "Setting up sysctl params for Kubernetes..."
cat <<EOT | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT

# 3. Apply Sysctl Params Without Reboot
echo "Applying sysctl params..."
sudo sysctl --system

# 4. Install Containerd
echo "Installing Containerd..."
sudo apt-get update && sudo apt-get install -y containerd

# 5. Configure Containerd
echo "Configuring Containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# 6. Restart Containerd
echo "Restarting Containerd..."
sudo systemctl restart containerd

# 7. Install Kubelet, Kubectl, and Kubeadm
echo "Installing Kubernetes components..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# if [ ! -d /etc/apt/keyrings ]; then
#   sudo mkdir -p -m 755 /etc/apt/keyrings
# fi

# Adding the Kubernetes APT key and source list
echo "Adding Kubernetes APT key and source list..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list and install Kubernetes components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl