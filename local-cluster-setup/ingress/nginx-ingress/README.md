Using kubectl 
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml

Using Helm 
$> helm repo add bitnami https://charts.bitnami.com/bitnami
$> helm repo update
$> kubectl create namespace ingress