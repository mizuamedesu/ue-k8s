# k3s HAクラスタ構成

| ホスト名 | ロール | CPU | RAM | IP | 備考 |
|---------|--------|-----|-----|------------|------|
| uc-k8s1p | Master | i3-7100 | 4GB | 10.240.0.37 | etcd, control-plane |
| uc-k8s2p | Master | i3-7100 | 4GB | 10.240.0.38 | etcd, control-plane |
| uc-k8s3p | Master | i3-7100 | 4GB | 10.240.0.39 | etcd, control-plane |
| uc-k8s4p | Worker | Xeon E5-2699v4 | 32GB | 10.240.0.40 | NFSサーバー, label: hardware=xeon |

## 設定詳細

### k3sバージョン
- v1.33.4+k3s1

### マスターノード設定
- 高可用性：etcd 3ノード構成
- Taint設定：node-role.kubernetes.io/master=true:NoSchedule
- Traefik無効化

### NFSサーバー（uc-k8s4p）
- パス：/opt/ue5-games
- 共有設定：10.240.0.0/16 (ro, no_root_squash)
- PV名：ue5-game-files-nfs (100Gi, ReadOnlyMany)
- PVC名：`ue5-game-files-pvc (namespace: game)

### ネットワーク
- サブネット：10.240.0.0/16
- Container Network：Flannel（k3sデフォルト）
