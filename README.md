
# alpine-voerkacloud
　　基于 alpine，适用于 voerkacloud 运行的容器镜像（python 版本 3.6.6）。

# 阅读指南

1. 指令解释不看不妨碍构建或运行，可跳过。

# 目录

[# 一、构建镜像](#一、构建镜像)

[# 二、运行容器](#二、运行容器)

[# 三、停止容器](#三、停止容器)

[# 四、小贴士](#四、小贴士)

# 一、构建镜像

## 构建配置

　　无

##  <span style='color: #dd4b39;'>构建指令</span>

　　如果没有远程镜像，或需要自己构建，则：

```shell
bash build.sh
```

　　如果有远程镜像，则无需构建。

## 指令解释
1. `build.sh` 内容如下：

    ```shell
    docker build -f ./Dockerfile -t meeyi/voerkacloud:v1.2.python3.6.6.alpine3.7 .
    ```
    　　其中：  
    - `-f ./Dockerfile` 指定了 `Dockerfile` 路径；  

    - `-t meeyi/voerkacloud:v1.2.python3.6.6.alpine3.7` 指定了构建成的镜像名称，根据需要自行修改；  

    - `.` 指定了构建时的工作目录，所以构建脚本中可以使用 `.` 来代替工作目录，访问工作目录下的文件夹及文件。
<br><br>
2. `Dockerfile` 内容如下：

    ```dockerfile
    # 指定基础镜像名称
    FROM python:3.6.6-alpine3.7  

    # 指定工作目录
    WORKDIR /app

    # 指定数据卷
    VOLUME /app

    # 复制必要文件
    COPY install.sh /app/install.sh
    COPY startup.sh /app/startup.sh
    COPY get-pip.py /app/get-pip.py
    COPY requirements.txt /app/requirements.txt

    # 执行必要指令
    RUN \
        # 更新软件源为国内，加快构建速度
        echo 'http://mirrors.aliyun.com/alpine/v3.7/main' > /etc/apk/repositories && \
        echo 'http://mirrors.aliyun.com/alpine/v3.7/community' >>/etc/apk/repositories && \
        
        # 然后使能该更新，接着安装必要的软件：
        # bash：shell 脚本解释器。用于执行 shell 脚本（不适用 alpine 自带的 sh 的原因是：sh 不能创建数组)
        # mysql-client：mysql 客户端。用于连接 mysql 数据库。
        # tzdata：时区数据库。用于提供不同的时区设置和数据。
        apk update && apk add bash mysql-client tzdata && \

        # 修改时区为 CST 即中国(China)上海(Shanghai)时区(Timezone)
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \ 
        echo "Asia/Shanghai" > /etc/timezone && \ 

        # 运行安装指令，安装 voerkacloud 运行环境
        bash install.sh

    # 镜像被实例化成容器后，若不指定指令，则默认运行该指令
    CMD ["/app/startup.sh"]
    ```

3. `install.sh` 内容如下：

    ```shell
    #!/bin/bash

    echo -e "\n\t\t\t-------- install.sh started --------\n\t\t\t"

    # 安装环境编译库
    echo -e "\tinstalling dev environments ..."
    for dev in gcc g++ python3-dev libffi-dev openssl-dev
    do
        apk add $dev 
    done
    echo -e "\tdev environments installed"

    # 安装 python 库
    echo -e "\tinstalling packages ..."
    cat ./requirements.txt | while read line || [ -n "$line" ]
    do
        echo -e "\tinstalling" $line " ..."
        pip install $line -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
        echo -e "\t----------" $line "installed. ----------" 
    done
    echo -e "\n\t\t\t-------- final check --------\n\t\t\t"

    # 检查

    requirements=()
    while read line
    do
    line=${line/%>=*/""}
    line=${line/%==*/""}
    line=`echo $line | tr "[A-Z]" "[a-z]"`
    requirements+=($line)
    done << EOT
    `cat ./requirements.txt`
    EOT
    #echo -e requirements "\n\t" ${requirements[@]}

    installed=()
    while read line
    do
    #echo $line
    line=${line/%\(*\)/""}
    line=`echo $line | tr "[A-Z]" "[a-z]"`
    installed+=($line)
    done << EOT
    `pip list --format=legacy`
    EOT
    #echo -e installed "\n\t" ${installed[@]}

    all_installed=1
    for r in ${requirements[@]}
    do
    #echo $r
    if ! [[ "${installed[@]}" =~ $r ]]; then 
        echo $r is not installed
        # echo -e "\t" installing ...
        # pip install $r
        # echo -e "\t" $r is installed
        all_installed=0
    fi
    done
    if [ $all_installed -eq 1 ]; then
    echo all packages installed.
    fi

    echo -e "\n\t\t\t-------- install.sh finished --------\n\t\t\t"
    ```

# 二、运行容器

##  <span style='color: #dd4b39;'>运行配置</span>

1. 准备 voerkacloud 资源（代码）文件夹  
　　可以直接将资源复制到某个文件夹，或者使用软连接的方式（详见：小贴士-创建软连接）。

2. 准备 voerkacloud 运行配置  
　　在资源文件夹下的 `data/settings/` 下创建一个 `yaml` 文件作为 voerkacloud 运行配置。  
　　示例 `for_test_run_on_192.168.110.12.yaml`：

```yaml
# 数据库配置
database:
    master:
        # 可取值mysql、sqlite、postgresql
        type: mysql
        enabled: True
        # 数据库服务地址或文件（sqlite）
        host: 172.17.0.1
        port: 3307
        #数据库实例名称
        dbname: voerka
        user: root
        password: root
        ##是否启用连接池，默认True
        pool_enabled:
        # 当连接池满时堵塞或等待的秒数，默认情况下如果连接池满时会出错
        timeout:
        #允许连接使用的秒数。
        stale_timeout:
        #None表示不限制
        max_connections:
        # 数据库初始化数据
    # 配置 只读的 从据据库 数组, 允许配置多个
#    slaves:

# VMS 配置
vms:
  - name: debug
    workers: 1
    transfers:
      - name: MQTTTransfer_debug
        workers: 1
        debug: False
        class: voerka.core.vms.transfer.mqtt.MQTTTransfer
        host: 192.168.110.12  # mqtt broker 主机 ip
        port: 1993            # mqtt broker 主机 端口
        username: test        # mqtt 连接用户名
        password: 123456      # mqtt 连接密码
        keepalive: 60         # mqtt 连接保持秒数
      - name: HTTPTransfer_debug
        workers: 1
        debug: True           # http 调试模式
        class: voerka.core.vms.transfer.http.HTTPTransfer
        host: 127.0.0.1       # http 主机 ip
        port: 8000            # http 主机 端口
        username: test        # 保留，暂不在此设置
        password: 123456      # 保留，暂不在此设置

# WEB 配置
webserver:
  - name: hispro
    url: 192.168.110.12:8000/hispro  # http 服务地址
    username: admin
    password: admin
```

##  <span style='color: #dd4b39;'>运行指令</span>

1. 模板

    ```shell
    bash run.sh \
    -c <VC 容器名> \
    -i <VC 镜像名> \
    [-w <VC 容器工作目录>] \
    -d <VC 资源文件夹> \
    [-p <VC 端口>] \
    -m <MYSQL 容器名>
    ```

2. 示例：

    ```shell
    bash run_eg.sh
    ```

    　　其中 `run_eg.sh` 内容如下：

    ```shell
    #!/usr/bin/bash

    bash run.sh \
    -c xxx_voerkacloud \
    -i meeyi/voerkacloud:v1.2.python3.6.6.alpine3.7 \
    -w $(pwd) \
    -d `readlink -f $(pwd)/src` \
    -p 8000 \
    -m xxx_mysql
    ```

    　　其中：
    - `-w $(pwd)`：指定了容器工作目录为 `run_eg.sh` 所在目录；  

    - `-d $(readlink -f $(pwd)/src) `：指定了 voerkacloud 资源文件夹为当前目录下的 src。  

    　　注1：这里必须使用绝对路径，这是为了让 voerkacloud 运行时能找到正确的路径而设；`readlink -f $(pwd)/src` 以获得 `$(pwd)/src` 的绝对路径。  

    　　注２：该绝对路径已作为容器环境变量传入，在容器的任何地方都可以通过 `$VC_SRC` 来访问到，比如在 `startup.sh` 就使用它来引用 voerkacloud 程序的主入口。  

## 指令解释

1. `run.sh` 内容如下：

    ```shell
    #!/usr/bin/bash

    VC_CTNER=
    VC_IMG=
    VC_PWD=$(pwd)
    VC_DATA=
    VC_PORT=8000
    VC_MYSQL=

    while getopts "c:i:w:d:p:m:" arg  # 选项后面的冒号表示该选项需要参数
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
                VC_PORT=$OPTARG  # 端口名
                ;;
            m)
                VC_MYSQL=$OPTARG  # 端口名
                ;;
        esac
    done

    if [ -z "$VC_CTNER" -o -z "$VC_IMG" -o -z "$VC_SRC" -o -z "$VC_MYSQL" ]; then
        echo -e "参数要求：-c <VC 容器名> -i <VC 镜像名> [-w <VC 容器工作目录>] -d <VC 资源文件夹> [-p <VC 端口>] -m <MYSQL 容器名>"
        exit
    fi

    echo -e "\t$VC_CTNER stopping ..."
    docker stop $VC_CTNER > /dev/null 2>&1
    docker rm $VC_CTNER > /dev/null 2>&1
    echo -e "\t$VC_CTNER restarting ..."

    docker run --name $VC_CTNER \

    --link $VC_MYSQL \         # 链接 mysql 容器
    -v $VC_PWD:/app \          # 容器工作目录 映射到 容器内部 /app 目录 

    -v $VC_SRC:$VC_SRC \       # voerkacloud 资源目录 映射到 容器内部 同路径目录
    -e VC_SRC=$VC_SRC \        # voerkacloud 资源目录绝对路径 映射到 容器内部 环境变量 VC_SRC

    # 另外一些环境变量，保留，暂无用
    -e VC_DATABASE=admin \
    -e VC_USER=pi \
    -e VC_PASSWORD=raspberry \
    -e VC_ROOT_PASSWORD=root \

    -p $VC_PORT:8000 \         # 端口映射
    -d                         # 运行模式：后台运行
    $VC_IMG                    # 镜像名称
    ```
2. `startup.sh` 内容如下：

    ```shell
    #!/bin/bash

    export VOERKA_SETTINGS="$VC_SRC/voerka/data/settings/for_test_run_on_192.168.110.12.yaml"
    python $VC_SRC/voerka/manage.py run &> $VC_SRC/log

    ```

    　　其中：第一行指定了 voerkacloud 的运行配置；第二行为运行指令，并将日志导入 $VC_SRC/log 以便外部查看（详见：小贴士-外部查看日志）。

# 三、停止容器

```shell
docker stop <voerkacloud 容器名>
```

# 四、小贴士

1. 创建软连接：`ln -s <被连接目标> <连接者>`  
　　示例：`ln -s ../voerkacloud src`

2. 外部查看日志：`tail -f <日志路径>`  
　　示例：`tail -f src/log`

