Here's a formatted version of your GitHub README file with added emojis for a more engaging look:

```markdown
# 🌐 Kubernetes Setup Using Multipass

## 🛠️ Prerequisites

- Install **Multipass** by following the instructions at [Multipass Installation](https://multipass.run/install).
- For Ubuntu, run the following command:
  ```bash
  sudo snap install multipass
  ```

## 🚀 Launching Instances

To launch the instances, run the following commands:

```bash
multipass launch oracular --name control-plane --cpus 2 -m 10G
multipass launch oracular --name workera --cpus 2 -m 15G
multipass launch oracular --name workerb --cpus 2 -m 15G
```

> **Note:** [Oracular](https://wiki.ubuntu.com/Releases) refers to the specific version being used.

## 🔍 View Launched Instances

To view the instances you have launched, use:

```bash
multipass list
```

## ⚙️ Preparing Instances for K8s Installation

### 1. Login to an Instance

```bash
multipass shell <instance_name>
```

### 2. Setup Required Sysctl Params

Create a configuration file for Kubernetes:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

### 3. Apply Sysctl Params Without Reboot

```bash
sudo sysctl --system
```

### 4. Install Containerd

Update the package list and install Containerd:

```bash
sudo apt-get update && sudo apt-get install -y containerd
```

### 5. Configure Containerd

Create the configuration directory and file:

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

### 6. Restart Containerd

```bash
sudo systemctl restart containerd
```

### 7. Install Kubelet, Kubectl, and Kubeadm

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

If the directory `/etc/apt/keyrings` does not exist, create it:

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
```

Add the Kubernetes APT key and source list:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Update the package list and install Kubernetes components:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## 🌟 Initializing Kubernetes Control Plane

### 1. Login to the Control-Plane Instance

```bash
multipass shell control-plane
```

### 2. Initialize the Control Plane

Run the following command to initialize Kubernetes:

```bash
sudo kubeadm init --pod-network-cidr=10.200.0.0/16
```

#### CIDR Blocks and Recommended CNI Plugins

You can use different CIDR blocks with various CNI plugins:

- **Flannel:**
  ```bash
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16
  ```
- **Calico:**
  ```bash
  sudo kubeadm init --pod-network-cidr=192.168.0.0/16
  ```
- **Weave Net:**
  ```bash
  sudo kubeadm init --pod-network-cidr=10.32.0.0/12
  ```
- **Cilium:**
  ```bash
  sudo kubeadm init --pod-network-cidr=10.32.0.0/16
  ```

### 📝 Output

The initialization process will provide output similar to:

```
[init] Using Kubernetes version: v1.31.2
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
...
Your Kubernetes control-plane has initialized successfully!
```

### 🔑 Post-Initialization Steps

To start using your cluster, run the following commands as a regular user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Alternatively, if you are the root user, you can run:

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```

You should now deploy a pod network to the cluster. Run:

```bash
kubectl apply -f [podnetwork].yaml
```

You can find options listed at: [Kubernetes Add-ons](https://kubernetes.io/docs/concepts/cluster-administration/addons/).

### 🤝 Joining Worker Nodes

To join worker nodes, run the following command on each worker node:

```bash
kubeadm join 10.147.56.251:6443 --token akbehv.3fwo3m8q7u090tvm \
    --discovery-token-ca-cert-hash sha256:d2a6b702d64f12e075821fcbece4e0f449bcdc79709cbb905370f3bd0b5290bc
```

### 📊 Status After Kubeadm Init

To check the status of your nodes, run this on the master node:

```bash
kubectl get nodes -o wide
```

### 📦 Transfer Kubeconfig to Local Machine

To access the Kubernetes cluster easily, transfer the kubeconfig from the control-plane node to your local desktop/laptop:

```bash
multipass transfer control-plane:/home/ubuntu/.kube/config ~/.kube/config
export KUBECONFIG=~/.kube/config
```

## 🌐 CNI Installation

For CNI installation, refer to the official documentation:
- [Cilium Getting Started](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

Run the following command to install Cilium:

```bash
cilium install --version 1.16.3
```

### 🛠️ Troubleshooting

After installing Cilium, if you encounter a "NodeHasDiskPressure" issue, you can resolve it by increasing the disk space:

```bash
multipass set local.workerb.disk=30G
```

You may also be interested in installing Docker inside the control-plane node. 🐳

Now how do we add new node to the cluster ?
 

multipass launch oracular --name workerc --cpus 4 -m 50G

multipass shell workerc

Install Necessary Packages

Join the New Node to the Cluster
multipass shell control-plane

kubeadm token create --print-join-command

install required packages follow install_package.sh script
Join the new node to the cluster


