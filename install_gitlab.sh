#！/bin/bash

storage_type=$1

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

helm install stable/gitlab-ce --name gitlab-ce --namespace default \
    --set global.registry.address=${REGISTRY} \
    --set portal.debug=true \
    --set gitlabHost=${NODE_IP} \
    --set gitlabRootPassword=Gitlab12345 \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=31101 \
    --set service.ports.ssh.nodePort=31102 \
    --set service.ports.https.nodePort=31103 \
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
    --set redis.persistence.host.nodeName="${NODE_NAME}" 
}

with_pvc(){

./create_pvc.sh $portal_pvc
./create_pvc.sh $databasepvc
./create_pvc.sh $redispvc

helm install stable/gitlab-ce --name gitlab-ce --namespace default \
    --set global.registry.address=${REGISTRY} \
    --set portal.debug=true \
    --set gitlabHost=${NODE_IP} \
    --set gitlabRootPassword=Gitlab12345 \
    --set service.type=NodePort \
    --set service.ports.http.nodePort=31101 \
    --set service.ports.ssh.nodePort=31102 \
    --set service.ports.https.nodePort=31103 \
    --set portal.persistence.enabled=true \
    --set portal.persistence.existingClaim=$portal_pvc \
    --set database.persistence.enabled=true \
    --set database.persistence.existingClaim=$database_pvc \
    --set redis.persistence.enabled=true \
    --set redis.persistence.existingClaim=$redis_pvc 
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