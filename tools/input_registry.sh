#!/bin/sh

input_registry(){
    read -p "请输入registry[默认为$1]:" registry
    case "${registry}" in
        "") registry=$1
            ;;
    esac
    echo ${registry}
}

input_registry $1