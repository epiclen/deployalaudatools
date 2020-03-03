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
    ./tools/create_pvc.sh $NEXUS_PVC

    helm install stable/nexus --name nexus --namespace ${namespace} \
      --set global.registry.address=${REGISTRY} \
      --set nexus.service.nodePort=32010 \
      --set nexusProxy.env.nexusHttpHost=${NODE_IP} \
      --set nexusProxy.env.nexusDockerHost=${NODE_IP} \
      --set persistence.enabled=true \
      --set persistence.existingClaim=${NEXUS_PVC}
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