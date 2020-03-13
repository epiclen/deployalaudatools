#!/bin/sh

#如果是host安装按照node的资源选择一个
#nodeip也是同样

REGISTRY=$(docker info |grep 60080  |tr -d ' ')
NODE_NAME=""
NODE_IP=""
potal_path="/root/alauda/gitlab/portal"         ###potal的数据目录，一般不需要修改，若有规划，可修改为别的目录
database_path="/root/alauda/gitlab/database"    ###database的目录，一般不需要修改，若有规划，可修改为别的目录
redis_path="/root/alauda/gitlab/redis"          ###redis的目录，一般不需要修改，若有规划，可修改为别的目录
portal_pvc="portalpvc"          ###默认pvc的名字为portalpvc，需要事先在default命名空间下准备好这个pvc，可更改，但也需要事先创建好对应的pvc。
database_pvc="databasepvc"      ###默认pvc的名字为databasepvc，需要事先在default命名空间下准备好这个pvc，可更改，但也需要事先创建好对应的pvc。
redis_pvc="redispvc"           ###默认pvc的名字为redispvc，需要事先在default命名空间下准备好这个pvc，可更改，但也需要事先创建好对应的pvc。

with_hostpath(){

command="""
helm install ${chart_name} --name ${name} --namespace ${namespace} \
    --set global.registry.address=${REGISTRY} \
    --set portal.debug=true \
    --set gitlabHost=${NODE_IP} \
    --set gitlabRootPassword=Gitlab12345 \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=${http_port} \
    --set service.ports.ssh.nodePort=${ssh_port} \
    --set service.ports.https.nodePort=${https_port} \
    --set portal.persistence.enabled=false \
    --set portal.persistence.host.nodeName=${NODE_NAME} \
    --set portal.persistence.host.path="$potal_path" \
    --set portal.persistence.host.nodeName="${NODE_NAME}" \
    --set database.persistence.enabled=false \
    --set database.persistence.host.nodeName=${NODE_NAME} \
    --set database.persistence.host.path="$database_path" \
    --set database.persistence.host.nodeName="${NODE_NAME}" \
    --set redis.persistence.enabled=false \
    --set redis.persistence.host.nodeName=${NODE_NAME} \
    --set redis.persistence.host.path="$redis_path" \
    --set redis.persistence.host.nodeName="${NODE_NAME}" \
    ${sets}
    """
}

with_pvc(){

./tools/create_pvc.sh $portal_pvc
./tools/create_pvc.sh $database_pvc
./tools/create_pvc.sh $redis_pvc

command="""
helm install ${chart_name} --name ${name} --namespace ${namespace} \
    --set global.registry.address=${REGISTRY} \
    --set portal.debug=true \
    --set gitlabHost=${NODE_IP} \
    --set gitlabRootPassword=Gitlab12345 \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=${http_port} \
    --set service.ports.ssh.nodePort=${ssh_port} \
    --set service.ports.https.nodePort=${https_port} \
    --set portal.persistence.enabled=true \
    --set portal.persistence.existingClaim=$portal_pvc \
    --set database.persistence.enabled=true \
    --set database.persistence.existingClaim=$database_pvc \
    --set redis.persistence.enabled=true \
    --set redis.persistence.existingClaim=$redis_pvc \
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

#input begin
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
  read -p "请输入helm install的name,默认是gitlab-ce:" name
  case $name in
  "") name="gitlab-ce"
    ;;
  esac
done

read -p "请输入http node port[默认为31101]:" http_port
case "$http_port" in
    "") http_port=31101
        ;;
esac

read -p "请输入ssh node port[默认为31102]:" ssh_port
case "$ssh_port" in
    "") ssh_port=31102
        ;;
esac

read -p "请输入https node port[默认为31103]:" https_port
case "$https_port" in
    "") https_port=31103
        ;;
esac

read -p "请输入chart[默认为release/gitlab-ce]:" chart_name
case "$chart_name" in
    "") chart_name=release/gitlab-ce
        ;;
esac

read -p "需要添加其他set吗[注意填写不正确可能导致命令失败]:" sets

#input end

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
    ""|"y") ;;
    "n") exit 1
      ;;
    *) unset is_execute
      ;; 
  esac
done

$(echo $command)