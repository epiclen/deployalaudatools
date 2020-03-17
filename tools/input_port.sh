#!/bin/sh

read -p "$1" port
case "$port" in
    "") portt=$2
        ;;
esac

echo ${port}