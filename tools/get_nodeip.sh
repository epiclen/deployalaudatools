#!/bin/sh

get_nodeip(){
    ip=$(kubectl get nodes $1 -o jsonpath='{.status.addresses[0].address}')
    echo $ip
}

get_nodeip $1