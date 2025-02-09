# Dockerfile构建x-ui面板 镜像

## 分析enwaiax/x-ui镜像 history
```
docker images
>    enwaiax/x-ui   latest    b71d86a7c997   7 weeks ago    77.7MB

docker history b71d86a7c997
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
b71d86a7c997   7 weeks ago    CMD ["x-ui"]                                    0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    EXPOSE map[54321/tcp:{}]                        0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    HEALTHCHECK &{["CMD-SHELL" "wget --no-verbos…   0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    WORKDIR /usr/local/bin                          0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    VOLUME [/etc/x-ui]                              0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    COPY /usr/share/xray/ /usr/local/bin/bin/ # …   17.4MB    buildkit.dockerfile.v0
<missing>      7 weeks ago    COPY /usr/bin/xray /usr/local/bin/bin/xray-l…   28.3MB    buildkit.dockerfile.v0
<missing>      7 weeks ago    ARG TARGETARCH=amd64                            0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    COPY /go/x-ui/x-ui /usr/local/bin/x-ui # bui…   23.1MB    buildkit.dockerfile.v0
<missing>      7 weeks ago    RUN /bin/sh -c apk add --no-cache     ca-cer…   1.01MB    buildkit.dockerfile.v0
<missing>      7 weeks ago    ENV TZ=Asia/Shanghai                            0B        buildkit.dockerfile.v0
<missing>      7 weeks ago    LABEL org.opencontainers.image.authors=https…   0B        buildkit.dockerfile.v0
<missing>      2 months ago   CMD ["/bin/sh"]                                 0B        buildkit.dockerfile.v0
<missing>      2 months ago   ADD alpine-minirootfs-3.21.0-x86_64.tar.gz /…   7.84MB    buildkit.dockerfile.v0
```
## 将该镜像中/usr/local/bin 与x-ui相关文件 打包导出即可
## 编写Dockerfile
```
# 使用 Alpine 3.21.0 x86_64 作为基础镜像
FROM alpine:3.21.0
# ADD alpine-minirootfs-3.21.0-x86_64.tar.gz /

# 设置镜像的作者标签
MAINTAINER wufake70<wufake70@gmail.com>

# 设置环境变量 TZ
ENV TZ=Asia/Shanghai

# 安装必要的软件包，设置时区并清理缓存
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && rm -rf /var/cache/apk/*

# 定义构建参数 TARGETARCH
ARG TARGETARCH=amd64


# 拷贝x-ui相关文件
# ADD会将当前目录x-ui_core.tar.gz 自动解压 为/usr/local/bin/x-ui_core
ADD x-ui_core.tar.gz /usr/local/bin
# x-ui添加可执行权限
RUN chmod +x /usr/local/bin/x-ui_core/x-ui
RUN chmod +x /usr/local/bin/x-ui_core/bin/xray-linux-amd64
# 设置工作目录
WORKDIR /usr/local/bin/x-ui_core
# 直接复制当前路径中x-ui_core目录，到镜像中/usr/local/bin
# COPY x-ui_core/ /usr/local/bin/
# RUN chmod +x /usr/local/bin/x-ui
# RUN chmod +x /usr/local/bin/bin/xray-linux-amd64
# WORKDIR /usr/local/bin


# 创建数据卷
VOLUME ["/etc/x-ui"]

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:54321 || exit 1

# 暴露端口 54321
EXPOSE 54321

# 设置容器启动时执行的命令
CMD ["./x-ui"]
```
## 运行该脚本构建镜像
```
# 脚本名为Dockerfile 可省略-f参数，.表示以当前目录为相对路径(add,copy 都要使用相对目录)
docker build -t xx-ui .

# 可以使用绝对路径
# docker build -f Dockerfile -t xx-ui /
```
## 创建对应实例
```
mkdir x-ui && cd x-ui
docker run -itd \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name xx-ui --restart=unless-stopped \
    -p 80:54321 \
    xx-ui
```

## 对比原镜像
```
docker images
    REPOSITORY     TAG       IMAGE ID       CREATED        SIZE
    xx-ui         latest    434883b3ab9b   16 hours ago   137MB
    enwaiax/x-ui   latest    b71d86a7c997   7 weeks ago    77.7MB
```