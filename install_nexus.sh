#!/bin/bash

NODE_IP=""
NODE_NAME=""
HOST_PATH=/alauda/nexus
REGISTRY=$(docker info |grep 60080  |tr -d ' ')
NEXUS_PVC=nexus-pvc

with_hostpath(){
    helm install stable/nexus --name nexus --namespace ${namespace} \
      --set global.registry.address=${REGISTRY} \
      --set nexus.service.nodePort=32010 \
      --set nexusProxy.env.nexusHttpHost=${NODE_IP} \
      --set nexusProxy.env.nexusDockerHost=${NODE_IP} \
      --set persistence.host.nodeName=${NODE_NAME} \
      --set persistence.host.path=${HOST_PATH}
}

with_pvc(){
    ./create_pvc.sh $NEXUS_PVC

    helm install stable/nexus --name nexus --namespace ${namespace} \
      --set global.registry.address=${REGISTRY} \
      --set nexus.service.nodePort=32010 \
      --set nexusProxy.env.nexusHttpHost=${NODE_IP} \
      --set nexusProxy.env.nexusDockerHost=${NODE_IP} \
      --set persistence.enabled=true \
      --set persistence.existingClaim=${NEXUS_PVC}
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