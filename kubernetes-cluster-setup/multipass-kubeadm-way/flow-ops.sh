#!/bin/bash
set -euo pipefail

echo "✅ Creating namespaces..."
kubectl create ns lab 
kubectl create ns istio-system 
kubectl create ns istio-ingress 
kubectl create ns monitoring 

echo "✅ Adding Helm repositories..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "✅ Installing Istio Base and Istiod..."
helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace --set meshConfig.accessLogFile="/dev/stdout"
helm install istiod istio/istiod -n istio-system --wait --set meshConfig.accessLogFile="/dev/stdout"

echo "✅ Enabling automatic sidecar injection in lab namespace..."
kubectl label namespace lab istio-injection=enabled --overwrite

echo "✅ Setting PeerAuthentication to STRICT mTLS..."
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF

echo "✅ Installing Istio Ingress Gateway..."
helm install istio-ingress istio/gateway -n istio-ingress 

echo "✅ Installing MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

echo "✅ Waiting for MetalLB components to be ready..."
kubectl wait --namespace metallb-system --for=condition=Available deployment controller --timeout=120s
kubectl wait --namespace metallb-system --for=condition=Available deployment webhook-service --timeout=120s


echo "✅ Configuring MetalLB address pool..."
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: ip-pool
spec:
  addresses:
    - 192.168.0.100-192.168.0.200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  namespace: metallb-system
  name: l2-adv
spec:
  ipAddressPools:
    - ip-pool
EOF

echo "✅ Installing Prometheus Stack..."
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring 

echo "🎉 Setup completed successfully!"
