k3d cluster create --config cluster-setup/k3d-config.yaml

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update


kubectl create namespace istio-system
helm install istio-base istio/base -n istio-system --wait
helm install istiod istio/istiod -n istio-system --wait


