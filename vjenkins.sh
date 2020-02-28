#!/bin/bash

environment="business" #环境：global business,默认是业务集群
storage="pvc" #存储方式 默认是pvc

gitlab_name="gitlab" #GitLab服务器名字
gitlab_url="" #GitLab服务器地址
gitlab_token="" #GitLab凭据token

#安装顺序
#gitlab->jenkins

#NODE_NAME需要检测node中资源最丰富的node
#global vip是global集群的master ip
#TOKEN也是devops-apiserver的集群(global)获取
NODE_NAME="acp2-master-1"            ###需要修改为集群中实际存放jenkins数据的某个节点的name，通过 kubectl get no 命令获取到的 name
path="/root/alauda/jenkins"          ###默认数据目录为/root/alauda/jenkins，若有需要可更改。
password="Jenkins12345"              ###默认密码为Jenkins12345，若有需要可更改
REGISTRY=$(docker info |grep 60080  |tr -d ' ')
ACP_NAMESPACE=<cpaas-system>     ## 改成部署时， --acp2-namespaces 参数指定的值，默认是cpaas-system
pvc_name="jenkinspvc"                ###默认pvc的名字为jenkinspvc，需要事先在default命名空间下准备好这个pvc，可更改，但也需要事先创建好对应的pvc。
global_vip="1.1.1.1"                 ###需要修改为平台的访问地址，如果访问地址是域名，就必须配置成域名，因为 jenkins 需要访问 global 平台的 erebus，如果平台是域名访问的话，erebus 的 ingress 策略会配置成只能域名访问。
TOKEN=       ### 如何获取token，到devops-apiserver所在集群（一般为global集群）执行：echo $(kubectl get secret -n ${ACP_NAMESPACE} $(kubectl get secret -n ${ACP_NAMESPACE} | grep devops-apiserver-token |awk '{print $1}') -o jsonpath={.data.token} |base64 --d)

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
    url: <Jenkins Location URL>
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
    url: <Jenkins Location URL>
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
    url: <Jenkins Location URL>
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
    url: <Jenkins Location URL>
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
}