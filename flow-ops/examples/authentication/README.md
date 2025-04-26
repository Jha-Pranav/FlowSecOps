kubectl create ns foo
kubectl label namespace foo istio-injection=enabled --overwrite 
kubectl apply -f flow-ops/examples/authentication/httpbin.yaml -n foo
kubectl apply -f flow-ops/examples/authentication/curl.yaml -n foo

kubectl create ns bar
kubectl label namespace bar istio-injection=enabled --overwrite 
kubectl apply -f flow-ops/examples/authentication/httpbin.yaml -n bar
kubectl apply -f flow-ops/examples/authentication/curl.yaml -n bar

kubectl create ns legacy
kubectl apply -f flow-ops/examples/authentication/httpbin.yaml -n legacy
kubectl apply -f flow-ops/examples/authentication/curl.yaml -n legacy