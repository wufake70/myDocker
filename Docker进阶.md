# 容器数据卷

## 什么是容器数据卷

### docker的理念回顾

将应用和环境打包成一个镜像！

数据？如果数据都在容器中，那么我们容器删除，数据就会丢失！需求：数据可以持久化

MySQL，容器删除了，删库跑路！需求：MySQL数据可以存储在本地！

容器之间可以有一个数据共享的技术！Docker容器中产生的数据，同步到本地！

这就是卷技术！目录的挂载，将我们容器内的目录，挂载到Linux上面！

![image-20200611220811766](./img/image-20200611220811766.png)

### 总结一句话：容器的持久化和同步操作！容器间也是可以数据共享的！

## 使用数据卷

> 方式一：直接使用命令来挂载

```shell
docker run -it -v 主机目录:容器目录

# 测试
[root@localhost home]# docker run -it -v /home/ceshi:/home  centos  /bin/bash

# 启动起来的时候，我们可以通过docker inspect 容器id 来查看挂载情况：（见下图）
```

![image-20200611224010091](./img/image-20200611224010091.png)

测试文件的同步

![image-20200611224046109](./img/image-20200611224046109.png)

在容器内指定目录下添加或修改一个文件，会同步到主机指定目录下！反之，在主机目录下做相关操作，也会同步到容器对应的目录下！

再来测试！

1、停止容器

2、宿主机修改文件

3、启动容器

4、容器内的数据依旧是同步的！

![image-20200611224137284](./img/image-20200611224137284.png)

好处：我们以后修改只需要在本地修改即可，容器内会自动同步！

## 实战：安装MySQL

思考：MySQL的数据持久化的问题！

```shell
# 获取镜像
[root@localhost home]# docker pull mysql:5.7

# 运行容器，需要做数据挂载！ # 安装mysql,需要配置密码，这是要注意的点！
# 官方测试：docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag

# 启动我们的MySQL容器
-d	后台运行
-p	端口映射
-v	卷挂载
-e  环境配置
--name  容器名字
[root@localhost home]# docker run -d -p 3310:3306 -v /home/mysql/conf:/etc/mysql/conf.d -v /home/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql01 mysql:5.7

# 启动成功之后，我们在本地使用sqlyog 连接测试一下
# sqlyog —— 连接到服务器的3310 —— 3310和容器内的3306映射，这个时候我们就可以连接上了！

# 本地测试创建一个数据库，查看一下我们的映射的路径是否ok!
```

假设我们将容器删除

![image-20200611230752177](./img/image-20200611230752177.png)

发现，我们挂载到本地的数据卷依旧没有丢失，这就实现了容器数据持久化功能！

## 具名和匿名挂载

```shell
# 匿名挂载
-v 容器内路径
docker run -d -P --name nginx01 -v /etc/nginx nginx


# 查看所有卷的情况
[root@localhost data]# docker volume ls
DRIVER              VOLUME NAME
local               2dd0379216c9ee4441ed56f8ce53461c19abe78b8cfd024ac5fbe07c3b8f09ba

# 这里发现，这种就是匿名挂载，我们在 -v 后只写了容器内的路径，没有写容器外的路径！

# 具名挂载
[root@localhost home]# docker run -d -P --name nginx02 -v juming-nginx:/etc/nginx nginx
5ba5708389bf71b2156fdbcedc50a62b16ac27adb2a3dfac42c52e9da5ace79f
[root@localhost home]# docker volume ls
DRIVER              VOLUME NAME
local               juming-nginx

# 通过 -v 卷名：容器内路径
# 查看一下这个卷  # 先找到卷所在路径 docker volume inspect 卷名，如下图：
```

![image-20200611235522418](./img/image-20200611235522418.png)

所有的docker容器内的卷，没有指定目录的情况下都是在### /var/lib/docker/volumes/xxxx/_data下！
我们通过具名挂载可以方便的找到我们的一个卷，大多数情况使用 ### 具名挂载

```shell
# 如何确定是具名挂载还是匿名挂载，还是指定路径挂载！
-v	容器内路径		       # 匿名挂载
-v	卷名:容器内路径	 	 # 具名挂载
-v	/宿主机路径:容器内路径   # 指定路径挂载！
```

拓展：

```shell
# 通过 -v 容器内路径：ro 或 rw   改变读写权限
ro	 #readonly 只读
rw	 #readwrite 可读可写

# 一旦创建容器时设置了容器权限，容器对我们挂载出来的内容就有限定了！
docker run -d -P --name nginx05 -v juming:/etc/nginx:ro nginx
docker run -d -P --name nginx05 -v juming:/etc/nginx:rw nginx

# 默认是 rw
# ro 只要看到ro就说明这个路径只能通过宿主机来操作，容器内部是无法操作！
```

## 初始Dockerfile

Dockerfile 就是用来构建 docker镜像的构建文件！命令脚本！ 先体验一下！

通过这个脚本可以生成镜像，镜像是一层一层的，脚本是一个个的命令，每个命令都是最终镜像的一层！

```shell
# 创建一个dockerfile文件，名字可以随机，建议 dockerfile

[root@localhost docker-test-volume]# vim dockerfile
# 文件中的内容：指令(大写) 参数
FROM centos

VOLUME ["volume01","volume02"]

CMD echo"----end----"

CMD /bin/bash

# 这里的每个命令，就是镜像的一层！
```

![image-20200612003052844](./img/image-20200612003052844.png)

注意：我们这里的 dockerfile  是我们编写的文件名哦！

![image-20200612003717223](./img/image-20200612003717223.png)

这两个卷和外部一定有两个同步的目录！

![image-20200612003946028](./img/image-20200612003946028.png)

查看一下卷挂载在主机上的路径

### docker inspect 容器id

![image-20200612004608027](./img/image-20200612004608027.png)

测试一下刚才的文件是否同步出去了！

这种方式我们未来使用十分的多，因为我们通常会构建自己的镜像！

假设构建镜像的时候没有挂在卷，要手动镜像挂载即可： (参考上文### 具名和匿名挂载)

```shell
-v 卷名:容器内路径 
```

## 数据卷容器

### 多个mysql同步数据！

![image-20200612223759573](./img/image-20200612223759573.png)

![image-20200612224621379](./img/image-20200612224621379.png)

![image-20200612225358172](./img/image-20200612225358172.png)

在docker03下创建docker03文件后，进入docker01发现也依旧会同步过来：

![image-20200612225641266](./img/image-20200612225641266.png)

```shell
# 测试1：删除docker01后，docker02和docker03是否还可以访问原来docker01下创建的的文件？
# 测试1的结果为：依旧可以访问！！！

# 测试2：删除docker01后，docker02和docker03之间是否可以相互同步文件？
# 测试2的结果为：docket02和docker03之间一九可以完成同步！！！ 见下图：
```

![image-20200612231431551](./img/image-20200612231431551.png)

![image-20200612231603498](./img/image-20200612231603498.png)

### 多个mysql实现数据共享

```shell
➜  ~ docker run -d -p 3306:3306 -v /home/mysql/conf:/etc/mysql/conf.d -v /home/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql01 mysql:5.7
➜  ~ docker run -d -p 3307:3306 -e MYSQL_ROOT_PASSWORD=123456 --name mysql02 --volumes-from mysql01  mysql:5.7
# 这个时候，可以实现两个容器数据同步！
```

### 结论：

容器之间的配置信息的传递，数据卷容器的生命周期一直持续到没有容器使用为止。

但是一旦你持久化到了本地，这个时候，本地的数据是不会删除的！

---



# DockerFile

## DockerFile介绍

`dockerfile`是用来构建docker镜像的文件！命令参数脚本！

### 构建步骤：

1、 编写一个dockerfile文件

2、 docker build 构建称为一个镜像

3、 docker run运行镜像

4、 docker push发布镜像（DockerHub 、阿里云仓库)

查看官方是怎么做的！

![image-20200612233951676](./img/image-20200612233951676.png)

![image-20200612234022746](./img/image-20200612234022746.png)

很多官方镜像都是基础包，很多功能没有，我们通常会自己搭建自己的镜像！

官方既然可以制作镜像，那我们也可以！

## DockerFile构建过程

### 基础知识：

1、每个保留关键字(指令）都是必须是大写字母

2、执行从上到下顺序

3、# 表示注释

4、每一个指令都会创建提交一个新的镜像曾，并提交！

![image-20200612234419262](./img/image-20200612234419262.png)

Dockerfile是面向开发的，我们以后要发布项目，做镜像，就需要编写dockerfile文件，这个文件十分简单！

Docker镜像逐渐成企业交付的标准，必须要掌握！

DockerFile：构建文件，定义了一切的步骤，源代码

DockerImages：通过DockerFile构建生成的镜像，最终发布和运行产品。

Docker容器：容器就是镜像运行起来提供服务。


## DockerFile的指令

```shell
FROM			# 基础镜像，一切从这里开始构建
MAINTAINER		# 镜像是谁写的，姓名+邮箱
RUN				# 镜像构建的时候需要运行的命令
ADD				# 步骤：tomcat镜像，这个tomcat压缩包！ 添加内容
WORKDIR			# 镜像的工作目录
VOLUME			# 挂载的目录
EXPOSE          # 暴露端口配置，跟 -p 是一个道理
CMD				# 指定这个容器启动时要执行的命令,只有最后一个命令会生效，可悲替代
ENTRYPOINT		# 指定这个容器启动的时候要执行的命令，可以追加命令
ONBUILD			# 当构建一个被继承DockerFile 这个时候就会运行ONBUILD的指令。触发指令
COPY			# 类似ADD,将我们文件拷贝到镜像中
ENV				# 构建的时候设置环境变量，跟 -e 是一个意思

# CMD 和 ENTRYPOINT 的区别说明：（后面也会介绍）
# 若CMD 和 ENTRYPOINT 后跟的都是 ls -a 这个命令，当docker run 一个容器时，添加了 -l 选项，则CMD里的ls -a 命令就会被替换成-l;而ENTRYPOINT中的 ls -a会追加-l变成 ls -a -l  
```

![image-20200613000838850](./img/image-20200613000838850.png)

## 实战测试

Docker Hub中99%镜像都是从这个基础镜像过来的( ### FROM scratch )，然后配置需要的软件和配置来构建。

![image-20200613001130237](./img/image-20200613001130237.png)

> 创建一个自己的 centos

```shell
# 1、编写DockerFile文件，内容如下：
[root@localhost dockerfile]# cat mydockerfile-centos
FROM centos						
MAINTAINER ztx<123456@qq.com> 

ENV MYPATH /usr/local
WORKDIR $MYPATH

RUN yum -y install vim
RUN yum -y install net-tools

EXPOSE 80

CMD echo $MYPATH
CMD echo "----end----"
CMD /bin/bash

# 2、通过这个文件构建镜像
# 命令docker build -f dockerfile文件路径 -t 镜像名:[tag] .
[root@localhost dockerfile]# docker build -f mydockerfile-centos -t mycentos:0.1 .
....
Successfully built c987078b06cb
Successfully tagged mycentos:0.1

# 3、测试运行
```

### 对比：

### 之前的原生的centos

![image-20200613004551789](./img/image-20200613004551789.png)

### 我们增加之后的镜像

![image-20200613005056516](./img/image-20200613005056516.png)

注：net-tools 包含一系列程序，构成了 Linux 网络的基础。

我们可以列出本地镜像的变更历史：

![image-20200613005625844](./img/image-20200613005625844.png)

我们平时拿到一个镜像，可以研究一下它是怎么做的！



> CMD 和 ENTRYPOINT 的区别

### 测试CMD

```shell
# 编写dockerfile文件
$ vim dockerfile-test-cmd
FROM centos
CMD ["ls","-a"]
# 构建镜像
$ docker build  -f dockerfile-test-cmd -t cmd-test:0.1 .
# 运行镜像
$ docker run cmd-test:0.1
.
..
.dockerenv
bin
dev

# 想追加一个命令  -l 成为ls -al
$ docker run cmd-test:0.1 -l
docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "exec: \"-l\":
 executable file not found in $PATH": unknown.
ERRO[0000] error waiting for container: context canceled 
# cmd的情况下 -l 替换了CMD["ls","-l"]。 -l  不是命令,所以报错
```

### 测试ENTRYPOINT

```shell
# 编写dockerfile文件
$ vim dockerfile-test-entrypoint
FROM centos
ENTRYPOINT ["ls","-a"]
$ docker run entrypoint-test:0.1
.
..
.dockerenv
bin
dev
etc
home
lib
lib64
lost+found ...
# 我们的命令，是直接拼接在我们的ENTRYPOINT命令后面的
$ docker run entrypoint-test:0.1 -l
total 56
drwxr-xr-x   1 root root 4096 May 16 06:32 .
drwxr-xr-x   1 root root 4096 May 16 06:32 ..
-rwxr-xr-x   1 root root    0 May 16 06:32 .dockerenv
lrwxrwxrwx   1 root root    7 May 11  2019 bin -> usr/bin
drwxr-xr-x   5 root root  340 May 16 06:32 dev
drwxr-xr-x   1 root root 4096 May 16 06:32 etc
drwxr-xr-x   2 root root 4096 May 11  2019 home
lrwxrwxrwx   1 root root    7 May 11  2019 lib -> usr/lib
lrwxrwxrwx   1 root root    9 May 11  2019 lib64 -> usr/lib64 ....
```

Dockerfile中很多命令都十分的相似，我们需要了解它们的区别，我们最好的学习就是对比他们然后测试效果！

## 实战：Tomcat镜像

1、准备镜像文件tomcat压缩包，jdk压缩包！

![image-20200613151500712](./img/image-20200613151500712.png)

2、编写Dockerfile文件，官方命名: ### Dockerfile ，build会自动寻找这个文件，就不要 -f 指定了！

```shell
FROM centos
MAINTAINER kuangshen<123456@qq.com>

COPY readme.txt /usr/local/readme.txt

ADD jdk-8u161-linux-x64.tar.gz    /usr/local/
ADD apache-tomcat-8.0.53.tar.gz   /usr/local

RUN yum -y install vim
ENV MYPATH /usr/local
WORKDIR $MYPATH


ENV JAVA_HOME /usr/local/jdk1.8.0_161
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV CATALINA_HOME /usr/local/apache-tomcat-8.0.53
ENV CATALINA_BASH /usr/local/apache-tomcat-8.0.53
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/lib:$CATALINA_HOME/bin

EXPOSE 8080

CMD /usr/local/apache-tomcat-8.0.53/bin/startup.sh && tail -F /usr/local/apache-tomcat-8.0.53/bin/logs/catalina.out

```

3、构建镜像

```shell
# docker build -t diytomcat .     diytomcat是定义的镜像名
```

4、启动镜像，创建容器

```shell
# docker run -d -p 9090:8080 --name kuangshentomcat02 -v /home/kuangshen/build/tomcat/test:/usr/local/apache-tomcat-8.0.53/webapps/test -v /home/kuangshen/build/tomcat/tomcatlogs/:/usr/local/apache-tomcat-8.0.53/logs diytomcat

```

5、访问测试

![image-20200613175551231](./img/image-20200613175551231.png)

6、发布项目（由于做了卷挂载，我们就可以直接在本地发布项目了）

在/home/kuangshen/build/tomcat/test目录下创建WEB-INF目录，在里面创建web.xml文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
                               http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd"
           version="2.5">

</web-app>
```

在回到test目录，添加一个index.jsp页面：

```html
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>hello kuangshen</title>vim
</head>
<body>
Hello World!<br/>
<%
System.out.println("---my test web logs---");
%>
</body>
</html>
```

发现：test项目部署成功，可以直接访问！

![image-20200613180033633](./img/image-20200613180033633.png)

注意：这时进入/home/kuangshen/build/tomcat/tomcatlogs/目录下就可以看到日志信息了：

```shell
[root@localhost tomcatlogs]# cat catalina.out 
```

![image-20200613180355186](./img/image-20200613180355186.png)

之前一直访问失败是web.xml配置有问题，最后也是查看该日志提示，才得以解决！！！

我们以后开发的步骤：需要掌握Dockerfile的编写！我们之后的一切都是使用docker镜像来发布运行！

## 发布自己的镜像

> Docker Hub

1、地址 https://hub.docker.com/

2、确定这个账号可以登录

3、在我们服务器上提交自己的镜像

```shell
[root@localhost tomcat]# docker login --help

Usage:	docker login [OPTIONS] [SERVER]

Log in to a Docker registry.
If no server is specified, the default is defined by the daemon.

Options:
  -p, --password string   Password
      --password-stdin    Take the password from stdin
  -u, --username string   Username

# 登录dockerhub
[root@localhost tomcat]# docker login -u ztx115
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

4、登录完毕后就可以提交镜像了，就是一步 docker push

```shell
# push自己的镜像到服务器上！
[root@localhost tomcat]# docker push diytomcat
The push refers to repository [docker.io/library/diytomcat]
c5593011cd68: Preparing 
d3ce40b8178e: Preparing 
02084c67dcc9: Preparing 
2b7c1c6c89c5: Preparing 
0683de282177: Preparing 
denied: requested access to the resource is denied  # 拒绝

# push镜像的问题？
# 解决：增加一个tag         docker tag  指定镜像的id   dockerhub的用户名/镜像重命名:[tag]
[root@localhost tomcat]# docker tag bb64ab96b432 ztx115/tomcat:1.0
```

![image-20200613211709842](./img/image-20200613211709842.png)

### 注意：镜像的重命名前一定要加当前的dockerhub的用户名，否则将会push失败！！！！（如：把ztx115改成ztx,  push一定失败！）

```shell
# docekr push上去即可！  自己平时发布的镜像尽量带上版本号
[root@localhost tomcat]# docker push ztx115/tomcat:1.0
The push refers to repository [docker.io/ztx115/tomcat]
c5593011cd68: Pushed 
d3ce40b8178e: Pushed 
02084c67dcc9: Pushed 
2b7c1c6c89c5: Pushed 
0683de282177: Pushed 
1.0: digest: sha256:b6733deccf85ad66c6f4302215dd9ea63e1579817f15a099b5858785708ed408 size: 1372
```

![image-20200613210147709](./img/image-20200613210147709.png)

发现，提交时也是按照镜像的层级来进行提交的！



> 发布到阿里云镜像服务上（狂神视频截图）

1、登录阿里云

2、找到容器镜像服务

3、创建命名空间

![image-20200613212823736](./img/image-20200613212823736.png)

4、创建容器镜像仓库

![image-20200613213014849](./img/image-20200613213014849.png)

![image-20200613213135466](./img/image-20200613213135466.png)

![image-20200613213222587](./img/image-20200613213222587.png)

5、浏览阿里云

![image-20200613214159792](./img/image-20200613214159792.png)



使用阿里云容器镜像的参考官方指南即可！！！（即上图）

## 小结

![image-20200613214846464](./img/image-20200613214846464.png)

---



# Docker网络

##  理解Docker0

清空所有环境

> 测试

![image-20200613224119526](./img/image-20200613224119526.png)

```shell
# 问题： docker是如何处理容器网络访问的？
```

![image-20200613220806390](./img/image-20200613220806390.png)

```shell
# [root@localhost /]# docker run -d -P --name tomcat01 tomcat

# 查看容器的内部网络地址   ip addr,  发现容器启动的时候会得到一个 eth0@if43 ip地址，docker分配的！
[root@localhost /]# docker exec -it tomcat01 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
42: eth0@if43: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

# 思考：linux能不能ping通docker容器内部！
[root@localhost /]# ping 172.17.0.2
PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
64 bytes from 172.17.0.2: icmp_seq=1 ttl=64 time=0.476 ms
64 bytes from 172.17.0.2: icmp_seq=2 ttl=64 time=0.099 ms
64 bytes from 172.17.0.2: icmp_seq=3 ttl=64 time=0.105 ms
...
# linux 可以ping通docker容器内部
```

> 原理

1、我们每启动一个docker容器，docker就会给docker容器分配一个ip，我们只要装了docker，就会有一个docker01网卡。

桥接模式，使用的技术是veth-pair技术！

再次测试 ip addr，发现多了一对网卡 : 

![image-20200613224311838](./img/image-20200613224311838.png)

2、再启动一个容器测试，发现又多了一对网卡！！！

![image-20200613224610781](./img/image-20200613224610781.png)

```shell
# 我们发现这个容器带来网卡，都是一对对的
# veth-pair 就是一对的虚拟设备接口，他们都是成对出现的，一段连着协议，一段彼此相连
# 正因为有这个特性，veth-pair 充当一个桥梁，连接各种虚拟网络设备
# OpenStack，Docker容器之间的连接，OVS的连接都是使用veth-pair技术
```

3、我们来测试下tomcat01和tomcat02是否可以ping通！

```shell
[root@localhost /]# docker exec -it tomcat02 ping 172.17.0.2
PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
64 bytes from 172.17.0.2: icmp_seq=1 ttl=64 time=0.556 ms
64 bytes from 172.17.0.2: icmp_seq=2 ttl=64 time=0.096 ms
64 bytes from 172.17.0.2: icmp_seq=3 ttl=64 time=0.111 ms
...

# 结论：容器与容器之间是可以相互ping通的！！！
```

### 绘制一个网络模型图：

![image-20200613231046553](./img/image-20200613231046553.png)

### 结论：tomcat01 和 tomcat02 是公用一个路由器，即 docker0 ! 

所有的容器不指定网络的情况下，都是经 docker0 路由的，docker 会给我们的容器分配一个默认的可用ip



> 小结

Docker使用的是Linux的桥接技术，宿主机是一个Docker容器的网桥 docker0

![image-20200613232031835](./img/image-20200613232031835.png)

### 注意：Docker中所有网络接口都是虚拟的，虚拟的转发效率高！（内网传递文件）

只要容器一删除，对应的一对网桥就没有！

## --link

> 思考一个场景：我们编写了一个微服务，database url = ip ，项目不重启，数据库ip换掉了，我们希望可以处理这个问题，可以通过名字来访问容器？

```shell
# tomcat02 想通过直接ping 容器名（即"tomcat01"）来ping通，而不是ip，发现失败了！
[root@localhost /]# docker exec -it tomcat02 ping tomcat01
ping: tomcat01: Name or service not known

# 如何解决这个问题呢？
# 通过--link 就可以解决这个网络联通问题了！！！      发现新建的tomcat03可以ping通tomcat02
[root@localhost /]# docker run -d -P --name tomcat03 --link tomcat02 tomcat
87a0e5f5e6da34a7f043ff6210b57f92f40b24d0d4558462e7746b2e19902721
[root@localhost /]# docker exec -it tomcat03 ping tomcat02
PING tomcat02 (172.17.0.3) 56(84) bytes of data.
64 bytes from tomcat02 (172.17.0.3): icmp_seq=1 ttl=64 time=0.132 ms
64 bytes from tomcat02 (172.17.0.3): icmp_seq=2 ttl=64 time=0.116 ms
64 bytes from tomcat02 (172.17.0.3): icmp_seq=3 ttl=64 time=0.116 ms
64 bytes from tomcat02 (172.17.0.3): icmp_seq=4 ttl=64 time=0.116 ms

# 反向能ping通吗？       发现tomcat02不能oing通tomcat03
[root@localhost /]# docker exec -it tomcat02 ping tomcat03
ping: tomcat03: Name or service not known
```

探究：inspect  ！！！

![image-20200614002609300](./img/image-20200614002609300.png)

![image-20200614002832045](./img/image-20200614002832045.png)

其实这个tomcat03就是在本地配置了到tomcat02的映射：

```shell
# 查看hosts 配置，在这里发现原理！  
[root@localhost /]# docker exec -it tomcat03 cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.3	tomcat02 95303c12f6d9    # 就像windows中的 host 文件一样，做了地址绑定
172.17.0.4	87a0e5f5e6da
```

本质探究：--link  就是我们在hosts 配置中增加了一个 172.17.0.3	tomcat02   95303c12f6d9 （三条信息都是tomcat02 的）

我们现在玩Docker已经不建议使用 --link 了！！！

### 自定义网络，不使用docker0！

docker0问题：不支持容器名连接访问！

## 自定义网络

> 查看所有的docker网络

‘![image-20200614004445923](./img/image-20200614004445923.png)

### 网络模式

bridge  ：桥接 （docker默认，自己创建也使用bridge模式！）

none ：不配置网络

host  ：和宿主机共享网络

container  ：容器网络连通，容器直接互联！（用的少！局限很大！）

### 测试

```shell
# 我们之前直接启动的命令 (默认是使用--net bridge，可省)，这个bridge就是我们的docker0 
docker run -d -P --name tomcat01 tomcat   
docker run -d -P --name tomcat01 --net bridge tomcat
# 上面两句等价

# docker0（即bridge）默认不支持域名访问 ！ --link可以打通连接，即支持域名访问！

# 我们可以自定义一个网络！
# --driver bridge    		网络模式定义为 ：桥接
# --subnet 192.168.0.0/16	定义子网 ，范围为：192.168.0.2 ~ 192.168.255.255
# --gateway 192.168.0.1		子网网关设为： 192.168.0.1 
[root@localhost /]# docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 mynet
7ee3adf259c8c3d86fce6fd2c2c9f85df94e6e57c2dce5449e69a5b024efc28c
[root@localhost /]# docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
461bf576946c        bridge              bridge              local
c501704cf28e        host                host                local
7ee3adf259c8        mynet               bridge              local  	#自定义的网络
9354fbcc160f        none                null                local

```

### 自己的网络就创建好了：

![image-20200614011229854](./img/image-20200614011229854.png)



```shell
[root@localhost /]# docker run -d -P --name tomcat-net-01 --net mynet tomcat
b168a37d31fcdc2ff172fd969e4de6de731adf53a2960eeae3dd9c24e14fac67
[root@localhost /]# docker run -d -P --name tomcat-net-02 --net mynet tomcat
c07d634e17152ca27e318c6fcf6c02e937e6d5e7a1631676a39166049a44c03c
[root@localhost /]# docker network inspect mynet
[
    {
        "Name": "mynet",
        "Id": "7ee3adf259c8c3d86fce6fd2c2c9f85df94e6e57c2dce5449e69a5b024efc28c",
        "Created": "2020-06-14T01:03:53.767960765+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.0/16",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "b168a37d31fcdc2ff172fd969e4de6de731adf53a2960eeae3dd9c24e14fac67": {
                "Name": "tomcat-net-01",
                "EndpointID": "f0af1c33fc5d47031650d07d5bc769e0333da0989f73f4503140151d0e13f789",
                "MacAddress": "02:42:c0:a8:00:02",
                "IPv4Address": "192.168.0.2/16",
                "IPv6Address": ""
            },
            "c07d634e17152ca27e318c6fcf6c02e937e6d5e7a1631676a39166049a44c03c": {
                "Name": "tomcat-net-02",
                "EndpointID": "ba114b9bd5f3b75983097aa82f71678653619733efc1835db857b3862e744fbc",
                "MacAddress": "02:42:c0:a8:00:03",
                "IPv4Address": "192.168.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]


# 再次测试 ping 连接
[root@localhost /]# docker exec -it tomcat-net-01 ping 192.168.0.3
PING 192.168.0.3 (192.168.0.3) 56(84) bytes of data.
64 bytes from 192.168.0.3: icmp_seq=1 ttl=64 time=0.199 ms
64 bytes from 192.168.0.3: icmp_seq=2 ttl=64 time=0.121 ms
^C
--- 192.168.0.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.121/0.160/0.199/0.039 ms

# 现在不使用 --link,也可以ping 名字了！！！！！！
[root@localhost /]# docker exec -it tomcat-net-01 ping tomcat-net-02
PING tomcat-net-02 (192.168.0.3) 56(84) bytes of data.
64 bytes from tomcat-net-02.mynet (192.168.0.3): icmp_seq=1 ttl=64 time=0.145 ms
64 bytes from tomcat-net-02.mynet (192.168.0.3): icmp_seq=2 ttl=64 time=0.117 ms
^C
--- tomcat-net-02 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.117/0.131/0.145/0.014 ms

```

我们在使用自定义的网络时，docker都已经帮我们维护好了对应关系，推荐我们平时这样使用网络！！！



好处：

redis——不同的集群使用不同的网络，保证了集群的安全和健康

mysql——不同的集群使用不同的网络，保证了集群的安全和健康

![image-20200614015209053](./img/image-20200614015209053.png)

## 网络连通

![image-20200614013625192](./img/image-20200614013625192.png)

![image-20200614013801842](./img/image-20200614013801842.png)

```shell
# 测试打通 tomcat01 — mynet
[root@localhost /]# docker network connect mynet tomcat01

# 连通之后就是将 tomcat01 放到了 mynet 网络下！ （见下图）
# 这就产生了 一个容器有两个ip地址 ! 参考阿里云的公有ip和私有ip
[root@localhost /]# docker network inspect mynet
```

![image-20200614014544797](./img/image-20200614014544797.png)

```shell
# tomcat01 连通ok
[root@localhost /]# docker exec -it tomcat01 ping tomcat-net-01
PING tomcat-net-01 (192.168.0.2) 56(84) bytes of data.
64 bytes from tomcat-net-01.mynet (192.168.0.2): icmp_seq=1 ttl=64 time=0.124 ms
64 bytes from tomcat-net-01.mynet (192.168.0.2): icmp_seq=2 ttl=64 time=0.162 ms
64 bytes from tomcat-net-01.mynet (192.168.0.2): icmp_seq=3 ttl=64 time=0.107 ms
^C
--- tomcat-net-01 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.107/0.131/0.162/0.023 ms

# tomcat02 是依旧打不通的
[root@localhost /]# docker exec -it tomcat02 ping tomcat-net-01
ping: tomcat-net-01: Name or service not known
```

### 结论：假设要跨网络操作别人，就需要使用docker network connect  连通。。。

## 实战：部署Redis集群

![image-20200614124559172](./img/image-20200614124559172.png)

启动6个redis容器，上面三个是主，下面三个是备！

使用shell脚本启动！

```shell
# 创建redis集群网络
docker network create redis --subnet 172.38.0.0/16

# 通过脚本创建六个redis配置
[root@localhost /]# for port in $(seq 1 6);\
> do \
> mkdir -p /mydata/redis/node-${port}/conf
> touch /mydata/redis/node-${port}/conf/redis.conf
> cat <<EOF>>/mydata/redis/node-${port}/conf/redis.conf
> port 6379
> bind 0.0.0.0
> cluster-enabled yes
> cluster-config-file nodes.conf
> cluster-node-timeout 5000
> cluster-announce-ip 172.38.0.1${port}
> cluster-announce-port 6379
> cluster-announce-bus-port 16379
> appendonly yes
> EOF
> done

# 查看创建的六个redis
[root@localhost /]# cd /mydata/
[root@localhost mydata]# \ls
redis
[root@localhost mydata]# cd redis/
[root@localhost redis]# ls
node-1  node-2  node-3  node-4  node-5  node-6

# 查看redis-1的配置信息
[root@localhost redis]# cd node-1
[root@localhost node-1]# ls
conf
[root@localhost node-1]# cd conf/
[root@localhost conf]# ls
redis.conf
[root@localhost conf]# cat redis.conf 
port 6379
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip 172.38.0.11
cluster-announce-port 6379
cluster-announce-bus-port 16379
appendonly yes
```



```shell
docker run -p 6371:6379 -p 16371:16379 --name redis-1 \
-v /mydata/redis/node-1/data:/data \
-v /mydata/redis/node-1/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.11 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf

docker run -p 6372:6379 -p 16372:16379 --name redis-2 \
-v /mydata/redis/node-2/data:/data \
-v /mydata/redis/node-2/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.12 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf

docker run -p 6373:6379 -p 16373:16379 --name redis-3 \
-v /mydata/redis/node-3/data:/data \
-v /mydata/redis/node-3/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.13 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf

docker run -p 6374:6379 -p 16374:16379 --name redis-4 \
-v /mydata/redis/node-4/data:/data \
-v /mydata/redis/node-4/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.14 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf

docker run -p 6375:6379 -p 16375:16379 --name redis-5 \
-v /mydata/redis/node-5/data:/data \
-v /mydata/redis/node-5/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.15 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf

docker run -p 6376:6379 -p 16376:16379 --name redis-6 \
-v /mydata/redis/node-6/data:/data \
-v /mydata/redis/node-6/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.16 redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf
```

![image-20200614133829277](./img/image-20200614133829277.png)



```shell
[root@localhost conf]# docker exec -it redis-1 /bin/sh
/data # ls
appendonly.aof  nodes.conf
/data # redis-cli --cluster create 172.38.0.11:6379 172.38.0.12:6379 172.38.0.13:6379 172.38.0.14:6379 172.38.0.15:6379 172.38.0.16:6379 --cluster-replicas 1
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 172.38.0.15:6379 to 172.38.0.11:6379
Adding replica 172.38.0.16:6379 to 172.38.0.12:6379
Adding replica 172.38.0.14:6379 to 172.38.0.13:6379
M: c5551e2a30c220fc9de9df2e34692f20f3382b32 172.38.0.11:6379
   slots:[0-5460] (5461 slots) master
M: d12ebd8c9e12dbbe22e7b9b18f0f143bdc14e94b 172.38.0.12:6379
   slots:[5461-10922] (5462 slots) master
M: 825146ce6ab80fbb46ec43fcfec1c6e2dac55157 172.38.0.13:6379
   slots:[10923-16383] (5461 slots) master
S: 9f810c0e15ac99af68e114a0ee4e32c4c7067e2b 172.38.0.14:6379
   replicates 825146ce6ab80fbb46ec43fcfec1c6e2dac55157
S: e370225bf57d6ef6d54ad8e3d5d745a52b382d1a 172.38.0.15:6379
   replicates c5551e2a30c220fc9de9df2e34692f20f3382b32
S: 79428c1d018dd29cf191678658008cbe5100b714 172.38.0.16:6379
   replicates d12ebd8c9e12dbbe22e7b9b18f0f143bdc14e94b
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
....
>>> Performing Cluster Check (using node 172.38.0.11:6379)
M: c5551e2a30c220fc9de9df2e34692f20f3382b32 172.38.0.11:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 79428c1d018dd29cf191678658008cbe5100b714 172.38.0.16:6379
   slots: (0 slots) slave
   replicates d12ebd8c9e12dbbe22e7b9b18f0f143bdc14e94b
M: d12ebd8c9e12dbbe22e7b9b18f0f143bdc14e94b 172.38.0.12:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: e370225bf57d6ef6d54ad8e3d5d745a52b382d1a 172.38.0.15:6379
   slots: (0 slots) slave
   replicates c5551e2a30c220fc9de9df2e34692f20f3382b32
S: 9f810c0e15ac99af68e114a0ee4e32c4c7067e2b 172.38.0.14:6379
   slots: (0 slots) slave
   replicates 825146ce6ab80fbb46ec43fcfec1c6e2dac55157
M: 825146ce6ab80fbb46ec43fcfec1c6e2dac55157 172.38.0.13:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.

```

docker搭建redis集群完成！

![image-20200614141549867](./img/image-20200614141549867.png)

我们使用docker之后，所有的技术都会慢慢变得简单起来！

---



# Springboot微服务打包Docker镜像

1、构建springboot项目，打包应用

![image-20200614155721369](./img/image-20200614155721369.png)

2、编写Dockerfile，连同项目的jar包一并上传指定目录下

![image-20200614153734161](./img/image-20200614153734161.png)

![image-20200614154114656](./img/image-20200614154114656.png)

3、构建镜像

![image-20200614154355597](./img/image-20200614154355597.png)

4、创建项目容器，发布运行！！！

![image-20200614155034087](./img/image-20200614155034087.png)

![image-20200614155340519](./img/image-20200614155340519.png)

以后我们使用了Docker之后，给别人交付就是一个镜像即可！

