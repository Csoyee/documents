# Get Docker Engine


## Prerequisites

### uninstall old versions

만일 이전에 설치한 예전 버전의 docker 이 있다면 이를 삭제한다.

```bash
$ sudo apt-get remove docker docker-engine docker.io containered runc
```

### set up repository

1. update apt package index

```bash
$ sudo apt-get update
```

2. install packages to allow `apt` to use a repository over HTTP

- 아래 사용예에서 알 수 있듯이 https 를 경유하여 docker repository 를 사용하게 된다. 이를 위해서 관련 패키지를 설치한다.

```bash
$ sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
```

3. add docker's official GPG key

```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# verify
$ sudo apt-key fingerprint 0EBFCD88
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
```

4. set up stable repositor 


```bash
$ sudo add-apt-repository \
 "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) \
 stable"
```

## Install 

```bash
$ sudo apt-get update

$ sudo apt-get install docker-ce # docker-ce-cli 같이 깔림
$ sudo apt-get install containered.io
```


## Verify 

- `hello-world` 이미지를 수행하여 도커엔진이 제대로 수행되었는지 확인.

```bash
$ sudo docker run hello-world # (new command: sudo docker container run hello-world)

Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
1b930d010525: Pull complete
Digest: sha256:f9dfddf63636d84ef479d645ab5885156ae030f611a56f3a7ac7f2fdd86d7e4e
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```
- Docker run 명령을 수행하면 Docker 컨테이너의 바탕이되는 도커 이미지가 로컬 환경에 있는지 확인하고 만일 로컬에 없다면 이미지를 Docker repository 에서 다운로드해서 수행한다. 


- Docker web page 에는 docker run 으로 명시되어있으나 docker container run 과 동일하다.
- 기본적으로 Docker Run 명령은 세개의 파트: `[docker container run: 컨테이너 수행] [Docker 이미지명] [실행할 명령]`; 로 나누어진다. 이번에는 linux 이미지를 통해서 hello world 를 출력해보자. 아래와 같이 ubuntu image 를 다운받아오고 Hello World  메세지가 출력된다.

```bash
$ sudo docker container run ubuntu:latest /bin/echo 'Hello World'
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
5bed26d33875: Pull complete 
f11b29a9c730: Pull complete 
930bda195c84: Pull complete 
78bf9a5ad49e: Pull complete
Digest: sha256:bec5a2727be7fff3d308193cfde3491f8fba1a2ba392b7546b43a051853a341d
Status: Downloaded newer image for ubuntu:latest

Hello World
```


## Container LifeCycle

- 이미지가 있으면 컨테이너를 생성할 수 있다. 컨테이너는 다음과 같은 라이프 사이클을 갖는다.
```
                              docker conatiner run (using image)
--------------------> 생성 ------ Docker Image -----------> 시작 -----------------> 정지 ------------------> 삭제
docker container create       docker container start         docker container stop    docker container rm
(using image)                                                   <-----------------
                                                              docker continer start
```

### Docker Container Create

- 이미지로부터 컨테이너를 생성함. 이미지에 포함될 리눅스 디렉토리나 파일의 스냅샷을 취한다. 단 단순히 컨테이너를 생성하기만 할 뿐 시작하는 것은 아니다.


### Docker Container Run

- 이미지로부터 컨테이너를 생성 + 시작 하는 명령이다 (create and start). 예시로 리눅스 bash 프로세스를 수행해보겠다.

```bash
$ sudo docker container run -it --name "test" ubuntu /bin/bash
root@278a8699a65c:/#
```

- 그러면 콘솔 프롬프드가 변하는 것을 알 수 있으며 컨테이너 안에서 linux 서버와 같이 명령 조작을 할 수 있게된다. 
- 컨테이너를 종료시키려면 exit 명령을 통해 쉘을 종료시킨다.

- 종료 전에 docker ps 를 통해서 process 상태를 보면 아래와 같이 ubuntu image 를 확인할 수 있다.
```bash
$ sudo docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
278a8699a65c        ubuntu              "/bin/bash"         18 seconds ago      Up 15 seconds                           test
```

### Docker Container start/stop/rm

- 컨테이너의 시작, 종류, 삭제에 사용된다.
- 위에서 시작한 container 을 종료하지 않은 상태에서 아래 명령을 통해 멈출 수 있다. 이 때 바로 시작하면 container 이 시작되지만 rm 이후에는 failed to start containers 에러가 뜬다.
```bash
$ sudo docker container stop test
test
```

## Get Docker Info

### Docker version:

```bash
$ sudo docker version
```

### Docker System Info 
- docker 실행 환경의 상세 설정을 확인할 수 있다. (컨테이너의 수, 도커 버전, 스토리지 드라이버 종류, OS, ... )


```bash
$ sudo docker system info
```

### Docker Images

- 현재 시스템에서 사용 가능한 이미지 리스트를 출력해보자
- 위에서 ubuntu, hello-world 이미지를 다운받아 사용했기 때문에 지금 두 개의 image 가 출력된다.

```bash
$ sudo docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              latest              4e5021d210f6        2 weeks ago         64.2MB
hello-world         latest              fce289e99eb9        15 months ago       1.84kB
```


### Docker status

- docker stats : cpu, memory 사용량 등을 모니터링 할 수 있음.

- df: docker 가 사용하고 있는 디스크의 이용 상황 등이 출력됨

```bash
$ sudo docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              2                   2                   64.21MB             0B (0%)
Containers          4                   0                   0B                  0B
Local Volumes       0                   0                   0B                  0B
Build Cache         0                   0                   0B                  0B
```


