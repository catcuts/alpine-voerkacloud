FROM python:3.6.6-alpine3.7

WORKDIR /app
VOLUME /app
COPY install.sh /app/install.sh
COPY startup.sh /app/startup.sh
COPY get-pip.py /app/get-pip.py
COPY requirements.txt /app/requirements.txt

RUN \
    echo 'http://mirrors.aliyun.com/alpine/v3.7/main' > /etc/apk/repositories && \
    echo 'http://mirrors.aliyun.com/alpine/v3.7/community' >>/etc/apk/repositories && \
    apk update && apk add bash mysql-client tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \ 
    echo "Asia/Shanghai" > /etc/timezone && \ 
    bash install.sh

CMD ["/app/startup.sh"]
