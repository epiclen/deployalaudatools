#!/bin/sh

read -p "请输入chart[默认为release/gitlab-ce]:" chart_name
case "$chart_name" in
    "") chart_name=release/gitlab-ce
        ;;
esac

echo $chart_name