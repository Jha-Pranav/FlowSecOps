
Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster. 

This tutorial is a modified version of the original developed by Kelsey Hightower(https://github.com/kelseyhightower/kubernetes-the-hard-way.git
). While the original one uses GCP as the platform to deploy kubernetes, I use a multipass to deploy a cluster on a local machine. 


## 🚀 Launching Instances

To launch the instances, run the following commands:

```bash
multipass launch noble --name kube-hw-control-plane-one --cpus 1 -m 5G --disk 10G
multipass launch noble --name kube-hw-control-plane-two --cpus 1 -m 3G --disk 10G
multipass launch noble --name kube-hw-worker-one --cpus 1 -m 3G --disk 10G
multipass launch noble --name kube-hw-worker-two --cpus 1 -m 3G --disk 10G
multipass launch noble --name kube-hw-loadbalancer --cpus 1 -m 3G --disk 10G
```

> **Note:** [noble](https://wiki.ubuntu.com/Releases) refers to the specific Ubuntu release version being used.


multipass delete kube-hw-control-plane-one kube-hw-control-plane-two  kube-hw-worker-one  kube-hw-loadbalancer 

multipass start kube-hw-control-plane-one kube-hw-control-plane-two  kube-hw-worker-one  kube-hw-loadbalancer 



cat > openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 10.147.56.25 
IP.2 = 10.147.56.142
IP.3 = 10.147.56.113
IP.4 = 10.147.56.88
IP.5 = 10.147.56.100 
EOF

ETCD 

cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.147.56.25 
IP.2 = 10.147.56.142
IP.3 = 127.0.0.1
EOF

for instance in kube-hw-control-plane-one kube-hw-control-plane-two; do
  scp ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    ${instance}:~/
done


sample file
/etc/ssl/openssl.cnf


for instance in kube-hw-worker-one kube-hw-worker-two; do
  scp kube-proxy.kubeconfig ${instance}:~/
done

for instance in kube-hw-control-plane-one kube-hw-control-plane-two; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done

for instance in kube-hw-control-plane-one kube-hw-control-plane-two; do
  ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
done

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster kube-hw-control-plane-one=https://10.147.56.25:2380,controller-2=https://10.147.56.142:2380 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-1=https://10.147.56.25:2380,controller-2=https://10.147.56.142:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

.ssh cat id_ed25519.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJoTb6VTBp8tTs/dBoqp5ma6sYVxIDfGmriHreyIZT7 pranav-pc@pranav-pc-Legion-T5-26IRB8

cat >> ~/.ssh/authorized_keys <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgjYXyypAeLUmr06Q9RYLqUYzUOGHeJ/jERdY8zvcGm ubuntu@kube-hw-control-plane-one
EOF




















Component version
multipass
kubernetes



credit : https://github.com/mmumshad/kubernetes-the-hard-way.git