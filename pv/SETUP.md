kubectl apply -f https://raw.githubusercontent.com/yandex-cloud/k8s-csi-s3/master/deploy/kubernetes/provisioner.yaml
kubectl apply -f https://raw.githubusercontent.com/yandex-cloud/k8s-csi-s3/master/deploy/kubernetes/driver.yaml
kubectl apply -f https://raw.githubusercontent.com/yandex-cloud/k8s-csi-s3/master/deploy/kubernetes/csi-s3.yaml

kubectl apply -f csi-s3-secret.yaml
kubectl apply -f csi-s3-storageclass.yaml

kubectl apply -f ue5-pv.yaml
kubectl apply -f ue5-pvc.yaml

kubectl apply -f ue5-deployment.yaml
kubectl apply -f ue5-service.yaml