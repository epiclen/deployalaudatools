#!/bin/sh

registry=$(docker info |grep 60080  |tr -d ' ')
PVC_NAME="sonarpvc"
NODE_PORT="31342"
NODE_NAME=""
NODE_IP=""
HOST_PATH="/cpaas/data/sonarqube"

with_hostpath(){
    helm install stable/sonarqube \
        --name sonarqube \
        --set plugins.useDefaultPluginsPackage=true \
        --set global.registry.address=$registry \
        --namespace=${namespace} \
        --set global.namespace=${namespace} \
        --set service.type=NodePort \
        --set service.nodePort=$NODE_PORT \
        --set postgresql.database.persistence.enabled=false \
        --set postgresql.database.persistence.host.nodeName=$NODE_NAME \
        --set postgresql.database.persistence.host.path=$HOST_PATH
}

with_pvc(){

    ./tools/create_pvc.sh $PVC_NAME

    helm install stable/sonarqube \
        --name sonarqube \
        --set plugins.useDefaultPluginsPackage=true \
        --set global.registry.address=$registry \
        --namespace=${namespace} \
        --set global.namespace=${namespace} \
        --set service.type=NodePort \
        --set service.nodePort=$NODE_PORT \
        --set postgresql.database.persistence.enabled=true \
        --set postgresql.database.persistence.existingClaim=$PVC_NAME
}

init_nodename(){
  NODE_NAME=$(./tools/check_node_name.sh)
  NODE_IP=$(./tools/get_nodeip.sh ${NODE_NAME})

  echo "NODE_NAME is:$NODE_NAME"
  echo "NODE_IP is:$NODE_IP"
}

#main

read -p "请输入namespace[默认为default]:" namespace
case "$namespace" in
    "") namespace="default"
        ;;
esac

while [ -z $storage_type ]
do
  read -p "请输入存储类型[0:pvc/1:hostpath,默认为0]:" storage_type
  case "$storage_type" in
      0 | 1) 
        ;;
      "") storage_type=0
        ;;
      *) unset storage_type
        ;;
  esac
done

init_nodename

case $storage_type in
    0)  with_pvc
        ;;
    1)  with_hostpath
        ;;
esac