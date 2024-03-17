Installation :

helm repo add haproxytech https://haproxytech.github.io/helm-charts    

helm install haproxy-kubernetes-ingress haproxytech/kubernetes-ingress \
 -n haproxy-controller -f override-values.yaml 