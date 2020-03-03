#!/bin/sh

REGISTRY=$(docker info |grep 60080  |tr -d ' ')
NODE_IP=""          ###此参数为部署时指定的访问地址，写当前集群中任意一个master节点的ip即可
NODE_NAME=""   ###需要修改为选择部署harbor节点的name，通过 kubectl get no 命令获取到的 name
HOST_PATH=/alauda/harbor   ###这个目录为harbor的数据目录路径，一般不需要修改，若有别的规划，可修改。
harbor_password="Harbor12345"  ####harbor的密码，默认不需要修改，若有规划，可改
db_password="Harbor4567"       ####harbor数据库的密码，默认不需要修改，若有规划，可改
redis_password="Redis789"      ###harbor的redis的密码，默认不需要修改，若有规划，可改
database_pvc=habordatabase   ###harbor数据库使用的pvc，需要事先在default下创建这个pvc
redis_pvc=harborredis        ###harbor的redis使用的pvc，需要事先在default下创建这个pvc
chartmuseum_pvc=harbormuseum   ###harbor使用的pvc，需要事先在default下创建这个pvc
registry_pvc=harborregistry     ###harbor的registry使用的pvc，需要事先在default下创建这个pvc
jobservice_pvc=harborjob        ###harbor使用的pvc，需要事先在default下创建这个pvc

with_hostpath(){

    echo hostpath

    helm install --name harbor --namespace ${namespace} stable/harbor \
    --set global.registry.address=${REGISTRY} \
    --set externalURL=http://${NODE_IP}:31104 \
    --set harborAdminPassword=$harbor_password \
    --set ingress.enabled=false \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=31104 \
    --set service.ports.ssh.nodePort=31105 \
    --set service.ports.https.nodePort=31106 \
    --set database.password=$db_password \
    --set redis.usePassword=true \
    --set redis.password=$redis_password \
    --set database.persistence.enabled=false \
    --set database.persistence.host.nodeName=${NODE_NAME} \
    --set database.persistence.host.path=${HOST_PATH}/database \
    --set redis.persistence.enabled=false \
    --set redis.persistence.host.nodeName=${NODE_NAME} \
    --set redis.persistence.host.path=${HOST_PATH}/redis \
    --set chartmuseum.persistence.enabled=false \
    --set chartmuseum.persistence.host.nodeName=${NODE_NAME} \
    --set chartmuseum.persistence.host.path=${HOST_PATH}/chartmuseum \
    --set registry.persistence.enabled=false \
    --set registry.persistence.host.nodeName=${NODE_NAME} \
    --set registry.persistence.host.path=${HOST_PATH}/registry \
    --set jobservice.persistence.enabled=false \
    --set jobservice.persistence.host.nodeName=${NODE_NAME} \
    --set jobservice.persistence.host.path=${HOST_PATH}/jobservice \
    --set AlaudaACP.Enabled=false
}

with_pvc(){

    echo pvc

    ./tools/create_pvc.sh $database_pvc
    ./tools/create_pvc.sh $redis_pvc
    ./tools/create_pvc.sh $chartmuseum_pvc
    ./tools/create_pvc.sh $registry_pvc
    ./tools/create_pvc.sh $jobservice_pvc

    helm install --name harbor --namespace ${namespace} stable/harbor \
    --set global.registry.address=${REGISTRY} \
    --set externalURL=http://${NODE_IP}:31104 \
    --set harborAdminPassword=$harbor_password \
    --set ingress.enabled=false \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=31104 \
    --set service.ports.ssh.nodePort=31105 \
    --set service.ports.https.nodePort=31106 \
    --set database.password=$db_password \
    --set redis.usePassword=true \
    --set redis.password=$redis_password \
    --set database.persistence.enabled=true \
    --set database.persistence.existingClaim=${database_pvc} \
    --set redis.persistence.enabled=true \
    --set redis.persistence.existingClaim=${redis_pvc} \
    --set chartmuseum.persistence.enabled=true \
    --set chartmuseum.persistence.existingClaim=${chartmuseum_pvc} \
    --set registry.persistence.enabled=true \
    --set registry.persistence.existingClaim=${registry_pvc} \
    --set jobservice.persistence.enabled=true \
    --set jobservice.persistence.existingClaim=${jobservice_pvc} \
    --set AlaudaACP.Enabled=false
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