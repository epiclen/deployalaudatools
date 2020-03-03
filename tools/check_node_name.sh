#!/bin/sh

check_node_name(){
    nodes=`kubectl get nodes|awk '{print $1}'|tail -n +2`
    b_nodeName=""
    b_value=-1
    for n in $nodes ;do
        let l=`kubectl get nodes $n -o jsonpath='{.status.capacity.cpu}'`-`kubectl get nodes $n -o jsonpath='{.status.allocatable.cpu}'`;
        if [ $l -gt $b_value ];then
            b_nodeName=$n
            b_value=$l
        fi
    done
    echo $b_nodeName
}

check_node_name