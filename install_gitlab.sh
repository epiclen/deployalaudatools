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

with_hostpath_values(){

values="""--set global.registry.address=${REGISTRY} \
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

with_pvc_values(){

./tools/create_pvc.sh $portal_pvc
./tools/create_pvc.sh $database_pvc
./tools/create_pvc.sh $redis_pvc

values="""--set global.registry.address=${REGISTRY} \
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
namespace=$(./tools/input_namespace.sh)

storage_type=$(./tools/input_storage_type.sh)

name=$(./tools/input_name.sh)

http_port=$(./tools/input_port.sh '请输入http node port[默认为31101]:' 31101)

ssh_port=$(./tools/input_port.sh '请输入ssh node port[默认为31102]:' 31102)

https_port=$(./tools/input_port.sh '请输入https node port[默认为31103]:' 31103)

chart_name=$(./tools/input_chart_name.sh)

chart_version=$(./tools/input_chart_version.sh)

sets=$(./tools/input_sets.sh)

#input end

init_nodename

case $storage_type in
    0)  with_pvc_values
        ;;
    1)  with_hostpath_values
        ;;
esac

command="""
helm install ${chart_name} ${chart_version}--name ${name} --namespace ${namespace} ${values}
"""

echo """生成的helm命令:$command"""
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