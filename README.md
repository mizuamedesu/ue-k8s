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
