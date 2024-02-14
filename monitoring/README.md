Add prometheus community helm repo 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update 

Create Monitoring ns
kubectl create ns monitoring 
kubens monitoring

helm pull 

helm install prometheus 
helm install prometheus-stack prometheus-community/kube-prometheus-stack
