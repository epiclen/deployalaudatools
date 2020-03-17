#!/bin/sh

input_namespace(){
    read -p "请输入namespace[默认为default]:" namespace
    case "${namespace}" in
        "") namespace="default"
            ;;
    esac
    echo ${namespace}
}

input_namespace