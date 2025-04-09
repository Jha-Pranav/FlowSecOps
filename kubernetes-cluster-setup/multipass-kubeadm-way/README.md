# ☸️ Kubernetes Cluster Setup with Multipass & Kubeadm

This guide helps you set up a lightweight local Kubernetes cluster using **Multipass** and **kubeadm**. It provisions 3 virtual Ubuntu machines with Multipass, installs container runtimes, sets up Kubernetes components, and connects nodes into a fully functional cluster using **Cilium** as the CNI plugin.

---

## 📋 Prerequisites

- ✅ **Multipass installed**
  - [Multipass Installation Guide](https://multipass.run/install)
  - For Ubuntu:
    ```bash
    sudo snap install multipass
    ```

- ✅ Basic knowledge of terminal & shell scripting
- ✅ Internet connectivity for downloading packages

---

## 🚀 TL;DR: Run Everything with One Script

This script provisions the cluster automatically:

```bash
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh
```

### 🧾 What It Does:
- Launches 3 VMs (`control-plane`, `workera`, and `workerb`) using Multipass with 2 CPUs, 3 GB RAM, and 50 GB storage each
- Disables swap
- Sets up sysctl for Kubernetes networking
- Installs containerd and configures it
- Installs Kubernetes components (kubelet, kubeadm, kubectl)
- Initializes the control-plane
- Installs **Cilium** as the CNI
- Joins worker nodes to the cluster
- Transfers kubeconfig to your local system for `kubectl` access

---

## 🧱 Step-by-Step: Manual Setup

### 🖥️ 1. Launch Multipass Instances

```bash
multipass launch noble --name control-plane --cpus 2 -m 3G -d 50G
multipass launch noble --name workera --cpus 2 -m 3G -d 50G
multipass launch noble --name workerb --cpus 2 -m 3G -d 50G
```

Check if instances are up:
```bash
multipass list
```

---

### 🔧 2. Prepare All Nodes

On **each** node:
```bash
multipass shell <node-name>
```

Then execute the following:

```bash
# Disable swap
sudo swapoff -a


# Load br_netfilter
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Install containerd
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes tools
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

### 🧩 3. Initialize Kubernetes Control Plane

```bash
multipass shell control-plane
```

Initialize cluster:
```bash
sudo kubeadm init --pod-network-cidr=10.32.0.0/16
```

Configure `kubectl` access:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

### 🌐 4. Install Cilium CNI

```bash
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz
cilium install --version 1.16.3
```

---

### 🔗 5. Join Worker Nodes

On control-plane:
```bash
kubeadm token create --print-join-command
```

Copy the output and run on **workera** and **workerb**:
```bash
multipass shell workera
# Paste the join command here
```

Repeat for `workerb`.

---

### 📥 6. Access Kubeconfig from Local Machine

On local terminal:
```bash
mkdir -p ~/.kube
multipass transfer control-plane:/home/ubuntu/.kube/config ~/.kube/config
chmod 600 ~/.kube/config
chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config
```

Test:
```bash
kubectl get nodes -o wide
```

---

## ➕ Add More Worker Nodes

```bash
multipass launch noble --name workerc --cpus 2 -m 3G -d 50G
multipass shell workerc
# Follow the same preparation and join steps
```

---

## 🛠️ Troubleshooting

- **DiskPressure / PodScheduling Issues?**
  ```bash
  multipass set local.<node>.disk=60G
  ```

- **Can't transfer kubeconfig?**
  Make sure your local `.kube` folder exists and is owned by your user:
  ```bash
  sudo chown -R $USER:$USER ~/.kube
  ```

---

## 📚 References

- [Kubernetes kubeadm Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Cilium Install Guide](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)
- [Multipass Docs](https://multipass.run/docs)

---

Happy Clustering! 🚀

