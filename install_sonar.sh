#!/bin/bash

storage_type=$1

registry=$(docker info |grep 60080  |tr -d ' ')
ACP_NAMESPACE="cpaas-system"
PVC_NAME="sonar_pvc"
NODE_PORT="31342"
NODE_NAME=""
NODE_IP=""
HOST_PATH="/cpaas/data/sonarqube"

with_hostpath(){
    helm install stable/sonarqube \
        --name sonarqube \
        --set plugins.useDefaultPluginsPackage=true \
        --set global.registry.address=$registry \
        --namespace=${ACP_NAMESPACE} \
        --set global.namespace=${ACP_NAMESPACE} \
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
        --namespace=${ACP_NAMESPACE} \
        --set global.namespace=${ACP_NAMESPACE} \
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