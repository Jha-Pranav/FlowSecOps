
https://istio.io/latest/docs/setup/install/helm/
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update


Install the Istio base chart which contains cluster-wide Custom Resource Definitions (CRDs) which must be installed prior to the deployment of the Istio control plane:
helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace  # --set meshConfig.accessLogFile="/dev/stdout"
helm upgrade istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace  --set meshConfig.accessLogFile="/dev/stdout"

helm install istiod istio/istiod -n istio-system --wait # --set meshConfig.accessLogFile="/dev/stdout"
helm upgrade istiod istio/istiod -n istio-system --wait  --set meshConfig.accessLogFile="/dev/stdout"

kubectl label namespace lab istio-injection=enabled --overwrite


(Optional) Install an ingress gateway:
kubectl create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress 

export INGRESS_NAME=istio-ingress
export INGRESS_NS=istio-ingress


K8S Gateway API 
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
