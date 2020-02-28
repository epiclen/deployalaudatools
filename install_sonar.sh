#!/bin/bash

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

    ./create_pvc.sh $PVC_NAME

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
  NODE_NAME=$(./check_node_name.sh)
  NODE_IP=$(./get_nodeip.sh ${NODE_NAME})

  echo "NODE_NAME is:$NODE_NAME"
  echo "NODE_IP is:$NODE_IP"
}

#main

read -p "请输入namespace[默认为default]:" namespace
case "$namespace" in
    "") namespace="default"
        ;;
esac

read -p "请输入存储类型[pvc/hostpath,默认为pvc]:" storage_type
case "$storage_type" in
    pvc | "") init_nodename
        with_pvc
        ;;
    hostpath) init_nodename
        with_hostpath
        ;;
    *) echo "输入的类型 $storage_type 错误"
    exit -1
    ;;
esac