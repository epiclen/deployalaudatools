#!/bin/bash

storage_type=$1
environment=$2

gitlab_name="gitlab"
gitlab_url=""
gitlab_token=""

NODE_NAME=""

#global vip是global集群的master ip
#TOKEN也是devops-apiserver的集群(global)获取
global_vip=""
TOKEN=""

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