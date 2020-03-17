#!/bin/sh

while [ -z $name ]
do
  read -p "请输入helm install的name,默认是gitlab-ce:" name
  case $name in
  "") name="gitlab-ce"
    ;;
  esac
done

echo ${name}