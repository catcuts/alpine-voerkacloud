#!/usr/bin/bash

VC_CTNER=
VC_IMG=
VC_PWD=$(pwd)
VC_DATA=
VC_HTTP_PORT=8000
VC_MYSQL=
VC_INIT=
VC_CONFIG_FILE=
VC_MODE=d

while getopts "c:i:w:d:p:m:n:f:u" arg  # 选项后面的冒号表示该选项需要参数
do
    case $arg in
        c)
            VC_CTNER=$OPTARG  # 容器名
            ;;
        i)
            VC_IMG=$OPTARG  # 镜像名
            ;;
        w)
            VC_PWD=$OPTARG  # 工作目录名
            ;;
        d)
            VC_SRC=$OPTARG  # 资源目录名
            ;;
        p)
            VC_HTTP_PORT=$OPTARG  # HTTP 端口名
            ;;
        m)
            VC_MYSQL=$OPTARG  # 端口名
            ;;
        n)
            VC_INIT=$OPTARG  # 初始化指令
            ;;
        f)
            VC_CONFIG_FILE=$OPTARG  # 配置文件
            ;;
        u)
            VC_MODE=it  # 容器运行模式
            ;;
    esac
done

echo -e "run.sh: voerkacloud 运行配置(VC_CONFIG_FILE): $VC_CONFIG_FILE"

if [ -z "$VC_CTNER" -o -z "$VC_IMG" -o -z "$VC_SRC" -o -z "$VC_MYSQL" ]; then
    echo -e "参数要求：\
    \n-c <VC 容器名> \
    \n-i <VC 镜像名> \
    \n[-w <VC 容器工作目录>] \
    \n-d <VC 资源文件夹> \
    \n[-p <VC HTTP 端口>] \
    \n-m <MYSQL 容器名> \
    \n-n <VC 初始化指令> \
    \n-f <VC 配置文件>"
    exit
fi

echo -e "\t$VC_CTNER stopping ..."
docker stop $VC_CTNER > /dev/null 2>&1
docker rm $VC_CTNER > /dev/null 2>&1
echo -e "\t$VC_CTNER restarting ..."

docker run --name $VC_CTNER \
--link $VC_MYSQL \
-v $VC_PWD:/app \
-v $VC_SRC:$VC_SRC \
-e VC_SRC=$VC_SRC \
-e VC_CONFIG_FILE=$VC_CONFIG_FILE \
-e VC_DATABASE=admin \
-e VC_USER=pi \
-e VC_PASSWORD=raspberry \
-e VC_ROOT_PASSWORD=root \
-p $VC_HTTP_PORT:8000 \
-$VC_MODE $VC_IMG $VC_INIT