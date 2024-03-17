GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml


kubectl get pod -n kubernetes-dashboard

kubectl create serviceaccount -n kubernetes-dashboard admin-user
kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user


To log in to your Dashboard, you need a Bearer Token. Use the following command to store the token in a variable.
token=$(kubectl -n kubernetes-dashboard create token admin-user)


Display the token using the echo command and copy it to use for logging in to your Dashboard.

echo $token


You can access your Dashboard using the kubectl command-line tool by running the following command:

kubectl proxy