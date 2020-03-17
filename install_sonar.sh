#!/bin/sh

registry=$(docker info |grep 60080  |tr -d ' ')
PVC_NAME="sonarpvc"
NODE_NAME=""
NODE_IP=""
HOST_PATH="/cpaas/data/sonarqube"

with_hostpath(){
  command="""
    helm install ${chart_name} ${chart_version}\
        --name ${name} \
        --set plugins.useDefaultPluginsPackage=true \
        --set global.registry.address=$registry \
        --namespace=${namespace} \
        --set global.namespace=${namespace} \
        --set service.type=NodePort \
        --set service.nodePort=${NODE_PORT} \
        --set postgresql.database.persistence.enabled=false \
        --set postgresql.database.persistence.host.nodeName=$NODE_NAME \
        --set postgresql.database.persistence.host.path=$HOST_PATH \
        ${sets}
        """
}

with_pvc(){

    ./tools/create_pvc.sh $PVC_NAME
  command="""
    helm install ${chart_name} ${chart_version}\
        --name ${name} \
        --set plugins.useDefaultPluginsPackage=true \
        --set global.registry.address=$registry \
        --namespace=${namespace} \
        --set global.namespace=${namespace} \
        --set service.type=NodePort \
        --set service.nodePort=${NODE_PORT} \
        --set postgresql.database.persistence.enabled=true \
        --set postgresql.database.persistence.existingClaim=$PVC_NAME \
        ${sets}
        """
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

while [ -z $name ]
do
  read -p "请输入helm install的name,默认是sonar:" name
  case $name in
  "") name="sonar"
    ;;
  esac
done

read -p "请输入node port[默认为31342]:" NODE_PORT
case "$NODE_PORT" in
    "") NODE_PORT=31342
        ;;
esac

read -p "请输入chart[默认为release/sonarqube]:" chart_name
case "$chart_name" in
    "") chart_name=release/sonarqube
        ;;
esac

read -p "请输入version[默认为不设置]:" chart_version
case "$chart_version" in
    "") chart_version=""
      ;;
    *) chart_version="--version=${chart_version} "
      ;;
esac

read -p "需要添加其他set吗[注意填写不正确可能导致命令失败]:" sets

init_nodename

case $storage_type in
    0)  with_pvc
        ;;
    1)  with_hostpath
        ;;
esac

echo "生成的helm命令:${command}"
while [ -z $is_execute ]
do
  read -p "是否立即执行['y' or 'n'默认是'y']" is_execute
  case $is_execute in
    ""|"y") is_execute="y"
      ;;
    "n") exit 1
      ;;
    *) unset is_execute
      ;; 
  esac
done

$(echo $command)