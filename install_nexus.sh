#!/bin/bash

storage_type=$1

NODE_IP=""
NODE_NAME=""
HOST_PATH=/alauda/nexus
REGISTRY=$(docker info |grep 60080  |tr -d ' ')
NEXUS_PVC=nexus-pvc

with_hostpath(){
    helm install stable/nexus --name nexus \
      --set global.registry.address=${REGISTRY} \
      --set nexus.service.nodePort=32010 \
      --set nexusProxy.env.nexusHttpHost=${NODE_IP} \
      --set nexusProxy.env.nexusDockerHost=${NODE_IP} \
      --set persistence.host.nodeName=${NODE_NAME} \
      --set persistence.host.path=${HOST_PATH}
}

with_pvc(){
    ./create_pvc $NEXUS_PVC

    helm install . --name nexus \
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

main(){
    echo -e "\e[1;41m"
    case "$1" in

        "")
        echo "请输入 hostpath 或者 pvc 来选定存储方式"
        ;;

        "hostpath" )
        init_nodename
        with_hostpath
        ;;

        "pvc" )
        init_nodename
        with_pvc
        ;;

    esac

echo -e "\e[0m"
}

#main
main $storage_type