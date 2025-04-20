# 🛡️ Generate Client and Server Certificates and Keys

This guide helps you generate root, server, and client certificates for use with Istio and Kubernetes.

---

## 📌 1. Root Certificate (CA)

Create a root certificate and private key to sign all service certificates.

```bash
mkdir example_certs1

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
  -subj "/O=pranav Inc./CN=jha-pranav.in" \
  -keyout k8s-lab.com.key \
  -out k8s-lab.com.crt
```

**Explanation:**
- `req -x509`: Generate a self-signed cert.
- `-sha256`: Use SHA-256.
- `-nodes`: Skip passphrase.
- `-days 365`: Valid for 1 year.
- `-newkey rsa:2048`: 2048-bit key.
- `-subj`: Subject details (CN = domain, O = organization).

---

## 🌐 2. Server Certificate for `local.lab.httpbin`

```bash
openssl req -out local.lab.httpbin.csr \
  -newkey rsa:2048 -nodes \
  -keyout local.lab.httpbin.key \
  -subj "/CN=local.lab.httpbin/O=Pranav's organization"

openssl x509 -req -sha256 -days 365 \
  -CA k8s-lab.com.crt \
  -CAkey k8s-lab.com.key \
  -set_serial 0 \
  -in local.lab.httpbin.csr \
  -out local.lab.httpbin.crt
```

**Explanation:**
- The `CN` should match the domain in your Ingress or Gateway.
- Signed using the root certificate.

---

## 🌐 3. Server Certificate for `local.lab.bookinfo.com`

```bash
openssl req -out local.lab.bookinfo.com.csr \
  -newkey rsa:2048 -nodes \
  -keyout local.lab.bookinfo.com.key \
  -subj "/CN=local.lab.bookinfo.com/O=helloworld organization"

openssl x509 -req -sha256 -days 365 \
  -CA k8s-lab.com.crt \
  -CAkey k8s-lab.com.key \
  -set_serial 1 \
  -in local.lab.bookinfo.com.csr \
  -out local.lab.bookinfo.com.crt
```

**Explanation:**
- Another server cert for a different domain.

---

## 👤 4. Client Certificate for Mutual TLS

```bash
openssl req -out client.k8s-lab.com.csr \
  -newkey rsa:2048 -nodes \
  -keyout client.k8s-lab.com.key \
  -subj "/CN=client.k8s-lab.com/O=Pranav's organization"

openssl x509 -req -sha256 -days 365 \
  -CA k8s-lab.com.crt \
  -CAkey k8s-lab.com.key \
  -set_serial 1 \
  -in client.k8s-lab.com.csr \
  -out client.k8s-lab.com.crt
```

**Explanation:**
- Required for client auth in mutual TLS.

---

## 🔐 5. Kubernetes TLS Secrets for Istio Gateway

```bash
kubectl create -n istio-ingress secret tls httpbin-credential \
  --key=local.lab.httpbin.key \
  --cert=local.lab.httpbin.crt

kubectl create -n istio-ingress secret tls bookinfo-credential \
  --key=local.lab.bookinfo.com.key \
  --cert=local.lab.bookinfo.com.crt
```

**Explanation:**
- Secrets used by Istio Gateway to terminate HTTPS connections.

---

## ⚠️ Browser Warning: `ERR_CERT_AUTHORITY_INVALID`

You might see the following warning:

> "Your connection is not private"
> `ERR_CERT_AUTHORITY_INVALID`

**Reason:** The certificate is **self-signed** and not trusted by your OS/browser.

**To Fix:**
- Import `k8s-lab.com.crt` into your system/browser's trust store.
- Or use a public CA like Let's Encrypt for real-world use.

---

## ✅ Example `curl` Command

```bash
curl -v https://local.lab.httpbin:443/status/418 --cacert certs/k8s-lab.com.crt 
```

Use `--cert` and `--key` when mutual TLS is enabled.

---


## 🔍 Identify Certificates

### ✅ 1. Server Certificate (`local.lab.httpbin`)
```bash
openssl x509 -in local.lab.httpbin.crt -noout -subject -issuer
```

### ✅ 2. Client Certificate (`client-certs.crt`)
```bash
openssl x509 -in client-certs.crt -noout -subject -issuer
```

---

## 🧾 Verify Certificates Are Signed by Your CA

### ✅ 3. Verify Server Certificate
```bash
openssl verify -CAfile k8s-lab.com.crt local.lab.httpbin.crt
```

### ✅ 4. Verify Client Certificate
```bash
openssl verify -CAfile k8s-lab.com.crt client-certs.crt
```

If both return `OK`, they are correctly signed by your custom root CA.

---

## 🔎 Check Server Certificate Over TLS

### ✅ 5. Fetch Server Cert Over TLS (Ingress or App):
```bash
openssl s_client -connect local.lab.httpbin:443 -showcerts -CAfile k8s-lab.com.crt
```

Configure a mutual TLS ingress gateway
kubectl create -n istio-ingress secret generic httpbin-credential \
  --from-file=tls.key=local.lab.httpbin.key \
  --from-file=tls.crt=local.lab.httpbin.crt \
  --from-file=ca.crt=k8s-lab.com.crt

SIMPLE -> MUTUAL 

curl -v https://local.lab.httpbin:443/status/418 --cacert certs/k8s-lab.com.crt --cert certs/client-certs.crt --key certs/client-certs.key


kubectl -n lab create secret generic httpbin-mtls-cacert --from-file=ca.crt=k8s-lab.com.crt
kubectl -n lab create secret tls httpbin-mtls --cert local.lab.httpbin.crt --key local.lab.httpbin.key
