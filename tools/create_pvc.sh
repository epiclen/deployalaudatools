#!/bin/sh

pvc_name=$1

create_pvc(){
echo "create pvc:$1"
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $1
  namespace: default
  annotations:
    volume.beta.kubernetes.io/storage-class: cephfs
    volume.beta.kubernetes.io/storage-provisioner: ceph.com/cephfs
  finalizers:
    - kubernetes.io/pvc-protection
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi              ###对应 pvc 的大小
  volumeMode: Filesystem
EOF

}

create_pvc $pvc_name