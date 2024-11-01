
# Debugging Errors

## Error 1
**Error Message:**
```shell
ubuntu@workera:/etc/kubernetes$ kubelet
E1031 16:39:17.867055    3589 run.go:72] "command failed" err="failed to construct kubelet dependencies: error reading /var/lib/kubelet/pki/kubelet.key, certificate and key must be supplied as a pair"
```

**Solution:**
- Run the command with `sudo` privileges:
  ```shell
  sudo kubelet
  ```

---

## Error 2
**Error Message:**
```shell
"command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
```

**Solution:**
1. Verify if `/var/lib/kubelet/config.yaml` exists. If you're using `kubeadm`, it should have created this file automatically. Missing config files can indicate an incomplete setup or configuration issue.
   
2. Reinitialize the node configuration with `kubeadm`:
   ```shell
   sudo kubeadm init phase kubelet-start
   ```

---

This document helps trace common  issues and provides quick solutions.