#!/bin/bash

get_nodeip(){
    ip=$(kubectl get nodes $1 -o jsonpath='{.metadata.labels.ip}')
    echo $ip
}

get_nodeip $1