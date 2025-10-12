## 構成

### ハードウェア
| ホスト名 | ロール | CPU | RAM | IP | 備考 |
|---------|--------|-----|-----|------------|------|
| uc-k8s1p | Master | i3-7100 | 4GB | 10.240.0.37 | etcd, control-plane |
| uc-k8s2p | Master | i3-7100 | 4GB | 10.240.0.38 | etcd, control-plane |
| uc-k8s3p | Master | i3-7100 | 4GB | 10.240.0.39 | etcd, control-plane |
| uc-k8s4p | Worker | Xeon E5-2699v4 (20C/40T) | 32GB | 10.240.0.40 | NFSサーバー + Kata Containers, label: hardware=xeon |

### ソフトウェア
- **k3s**: v1.33.4+k3s1 (軽量Kubernetes)
- **Kata Containers**: 3.21.0
- **NFS**: ゲームバイナリの共有ストレージ
- **Container Runtime**: containerd + Kata runtime

```
mizuame@uc-k8s4p:/opt/ue5-games$ ls -la /opt/ue5-games/
total 24
drwxr-xr-x 5 nobody nogroup 4096 Oct 11 09:55 .
drwxr-xr-x 4 root   root    4096 Oct 11 09:48 ..
drwxr-xr-x 6 nobody nogroup 4096 Oct 11 09:55 container
-rwxr-xr-x 1 nobody nogroup  260 Oct 11 09:55 containerServer.sh
drwxr-xr-x 5 nobody nogroup 4096 Oct 11 09:50 Engine
drwxr-xr-x 2 nobody nogroup 4096 Oct 11 09:51 Saved
mizuame@uc-k8s4p:/opt/ue5-games$ ls
container  containerServer.sh  Engine  Saved
mizuame@uc-k8s4p:/opt/ue5-games$
```

一旦共有NFS直下にぶち込む状態

```
sudo mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/
sudo nano /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
sudo systemctl restart k3s-agent
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
git clone https://github.com/wunderio/csi-rclone.git
cd csi-rclone
kubectl apply -f deploy/kubernetes/1.20
```