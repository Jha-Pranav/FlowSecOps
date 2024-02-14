```markdown
# Setting Up a Kubernetes Development Environment with Kind

Kind (Kubernetes in Docker) is a tool for running local Kubernetes clusters using Docker container "nodes." This makes it easy to set up and manage a Kubernetes environment for development and testing purposes.

## Installation

Install Kind using Homebrew:

```bash
brew install kind
```

## Create a Kind Cluster

Create a Kind cluster named "play-ground":

```bash
kind create cluster --name play-ground
```

You can also create a cluster using a custom configuration file:

```bash
kind create cluster --config=config.yaml
```


## Ingress Setup

Install the NGINX Ingress Controller for Kind:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
```

## LoadBalancer Setup

Install MetalLB, a load balancer implementation for Kubernetes:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

You need to provide MetalLB a range of IP addresses it controls. 
```bash
docker network inspect -f '{{.IPAM.Config}}' kind
```


Set up an address pool for MetalLB:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - 172.19.0.0-172.19.0.1
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF
```

## Local Registry

Run the following script to set up a local Docker registry:

```bash
#!/bin/sh

# Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" registry:2
fi


# Add the registry config to the nodes
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# Connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
```

This script creates a local Docker registry, configures the Kind cluster to use it, and documents(cm) the registry in Kubernetes.


### TODO List:

- Explore kube-proxy modes (iptables and ipvs)
- Set up a Container Network Interface (CNI)
- Mount a data folder from the host to a node inside the cluster
- Expose a service on NodePort 30950
- ISSUE : ingress-nginx-controller pod is getting into pending status because of Pod's node affinity/selector.

🚀 Happy Kubernetes-ing with Kind! 🚀
```
