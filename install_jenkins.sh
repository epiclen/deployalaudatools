#!/bin/sh

# storage_type
# environment

# gitlab_name
# gitlab_url
# gitlab_token

# NODE_NAME

#global vip是global集群的master ip
#TOKEN也是devops-apiserver的集群(global)获取
# global_vip
# TOKEN

path="/root/alauda/jenkins"
password="Jenkins12345"
REGISTRY=$(docker info |grep 60080  |tr -d ' ')
ACP_NAMESPACE=cpaas-system
pvc_name="jenkinspvc"

global_with_host(){
cat <<EOF > values.yaml
 
global:
  registry:
    address: ${REGISTRY}
Master:
  ServiceType: NodePort
  NodePort: 32001
  AdminPassword: "$password"
  gitlabConfigs:
    - name: ${gitlab_name}
      manageHooks: true
      serverUrl: ${gitlab_url}
      token: ${gitlab_token}
  Location:
    url: ${NODE_IP}
Persistence:
  Enabled: false
  Host:
    NodeName: ${NODE_NAME}
    Path: $path
AlaudaACP:
  Enabled: true
  JenkinsServiceName: "jenkins"
alaudapipelineplugin:
  consoleURL: ""
  apiEndpoint: ""
  apiToken: ""
  account: ""
  spaceName: ""
  clusterName: ""
  namespace: ""
AlaudaDevOpsCredentialsProvider:
  globalNamespaces: "${ACP_NAMESPACE}-global-credentials,${ACP_NAMESPACE}"
Erebus:
  Namespace: "${ACP_NAMESPACE}"
  URL: "https://erebus.${ACP_NAMESPACE}.svc.cluster.local:443/kubernetes"
 
EOF
}

global_with_pvc(){
cat <<EOF > values.yaml
 
global:
  registry:
    address: ${REGISTRY}
Master:
  ServiceType: NodePort
  NodePort: 32001
  AdminPassword: "$password"
  gitlabConfigs:
    - name: ${gitlab_name}
      manageHooks: true
      serverUrl: ${gitlab_url}
      token: ${gitlab_token}
  Location:
    url: ${NODE_IP}
Persistence:
  Enabled: true
  ExistingClaim="$pvc_name"
AlaudaACP:
  Enabled: true
  JenkinsServiceName: "jenkins"
alaudapipelineplugin:
  consoleURL: ""
  apiEndpoint: ""
  apiToken: ""
  account: ""
  spaceName: ""
  clusterName: ""
  namespace: ""
AlaudaDevOpsCredentialsProvider:
  globalNamespaces: "${ACP_NAMESPACE}-global-credentials,${ACP_NAMESPACE}"
Erebus:
  Namespace: "${ACP_NAMESPACE}"
  URL: "https://erebus.${ACP_NAMESPACE}.svc.cluster.local:443/kubernetes"
 
EOF

./tools/create_pvc.sh $pvc_name

}

business_with_host(){
cat <<EOF > values.yaml
  
global:
  registry:
    address: ${REGISTRY}
Master:
  ServiceType: NodePort
  NodePort: 32001
  AdminPassword: "$password"
  gitlabConfigs:
    - name: ${gitlab_name}
      manageHooks: true
      serverUrl: ${gitlab_url}
      token: ${gitlab_token}
  Location:
    url: ${NODE_IP}
Persistence:
  Enabled: false
  Host:
    NodeName: ${NODE_NAME}
    Path: $path
AlaudaACP:
  Enabled: true
  JenkinsServiceName: "jenkins"
alaudapipelineplugin:
  consoleURL: ""
  apiEndpoint: ""
  apiToken: ""
  account: ""
  spaceName: ""
  clusterName: ""
  namespace: ""
AlaudaDevOpsCredentialsProvider:
  globalNamespaces: "${ACP_NAMESPACE}-global-credentials,${ACP_NAMESPACE},kube-system"
AlaudaDevOpsCluster:
  Cluster:
    masterUrl: "https://$global_vip:6443"
    token: ${TOKEN}
Erebus:
  Namespace: "${ACP_NAMESPACE}"
  URL: "https://$global_vip:443/kubernetes"
 
EOF
}

business_with_pvc(){
cat <<EOF > values.yaml
  
global:
  registry:
    address: ${REGISTRY}
Master:
  ServiceType: NodePort
  NodePort: 32001
  AdminPassword: "$password"
  gitlabConfigs:
    - name: ${gitlab_name}
      manageHooks: true
      serverUrl: ${gitlab_url}
      token: ${gitlab_token}
  Location:
    url: ${NODE_IP}
Persistence:
  Enabled: true
  ExistingClaim: "$pvc_name"
AlaudaACP:
  Enabled: true
  JenkinsServiceName: "jenkins"
alaudapipelineplugin:
  consoleURL: ""
  apiEndpoint: ""
  apiToken: ""
  account: ""
  spaceName: ""
  clusterName: ""
  namespace: ""
AlaudaDevOpsCredentialsProvider:
  globalNamespaces: "${ACP_NAMESPACE}-global-credentials,${ACP_NAMESPACE},kube-system"
AlaudaDevOpsCluster:
  Cluster:
    masterUrl: "https://$global_vip:6443"
    token: ${TOKEN}
Erebus:
  Namespace: "${ACP_NAMESPACE}"
  URL: "https://$global_vip:443/kubernetes"
 
EOF

./tools/create_pvc.sh $pvc_name

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


while [ -z $environment_code ]
do
  read -p "请选择环境[0:业务集群/1:global集群,默认为0]:" environment_code
  case "$environment_code" in
    0|1) 
      ;;
    "") environment_code=0
      ;;
    *) unset environment_code
      ;;
  esac
done

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

while [ -z $gitlab_name ]
do
  read -p "请输入gitlab name:" gitlab_name
done

while [ -z $gitlab_url ]
do
  read -p "请输入gitlab url:" gitlab_url
done

while [ -z $gitlab_token ]
do
  read -p "请输入gitlab token:" gitlab_token
done

if [ $environment_code -eq 0 ]
then
  while [ -z $global_vip ]
  do
    read -p "请输入global vip:" global_vip
  done

  while [ -z $TOKEN ]
  do
    read -p "请输入global的token:" TOKEN
  done
fi

init_nodename

case $[ $environment_code*10+$storage_type ] in
  0)  business_with_pvc
      ;;
  1)  business_with_host
      ;;
  10) global_with_pvc
      ;;
  11) global_with_host
      ;;
esac

cat values.yaml

helm install stable/jenkins --name jenkins --namespace ${namespace} -f values.yaml