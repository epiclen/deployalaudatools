#!/bin/sh

read -p "请输入version[默认为不设置]:" chart_version
case "$chart_version" in
    "") chart_version=""
      ;;
    *) chart_version="--version=${chart_version} "
      ;;
esac

echo $chart_version