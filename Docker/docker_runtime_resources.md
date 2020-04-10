# Docker Runtime Options with Resources 



기본적으로 컨테이너는 리소스 제한을 갖지 않으며 호스트의 커널 스케줄러가 허용하는 리소스를 최대한 사용할 수 있다. 하지만 `docker run` command 에서 flag 를 주어서 얼마만큼 CPU 와 memory 를 사용할지 조절할 수 있다. 


시작하기 전에 커널에서 리눅스 기능을 제공해야하는데 지원 여부를 확인하기 위해서는 `docker info` command 를 통해서 알 수 있다. 만일 기능이 꺼져있으면 다음과 같은 결과가 나온다.

```
  WARNING: No swap limit support
```
해당 기능을 켜기 위해서는 [다음 세팅](https://docs.docker.com/engine/install/linux-postinstall/#your-kernel-does-not-support-cgroup-swap-limit-capabilities)을 해야한다.



## Docker in cgroupfs

- cgroup 은 프로세스 그룹별 자원 관리를 위한 인터페이스이다. cgroup 자체는 process group 을 만드는 역할을 하며 resource 에 대한 관리는 subsystem 을 통해서 이뤄지는데 결과적으로 cgroup 을 통해서: (1) 리소스 사용제한, (2) cpu 및 disk I/O 자원에 대한 우선순위 부여, (3) system resource 측정 등을 수행할 수 있다.

- 리소스 조절하는 법을 알아보기 전에 별도의 플래그 없이 정의된 컨테이너의 cgroup 설정들을 살펴보겠다. 현재 4개의 컨테이너를 띄운 상태이다.

### cgroup filesystem
- sysfs 나 procfs 와 같이 low-level filesystem interface 를 제공하며 일반적으로 `/sys/fs/cgroup` 에 cgroupfs 가 마운트된다. 

#### subsystem
- subsystem 을 통해서 그룹을 제어할 수 있으며 간략하게 몇가지를 살펴보면, memory 사용을 제한하고 사용량을 레포트하는 `mem_cgroup_subsys`, 개별 cpu와 memory node 를 할당하는 `cpuset_subsys`, block device 의 입출력을 제한하는 `blkio_subsys`, 네트워크 우선순위를 제어하는 `net_prio_subsys` 등이 존재한다. 이외에도 다른 subsystem 들도 존재한다.

#### Docker group in cgroupfs 
- cgroupfs 에서 docker group 을 찾아보면 다음과 같이 그룹들이 나온다.

```bash
csoyee@csoyee:/sys/fs/cgroup$ find -name docker  # find docker group
./cpuset/docker
./perf_event/docker
./devices/docker
./memory/docker
./freezer/docker
./net_cls,net_prio/docker
./cpu,cpuacct/docker
./pids/docker
./blkio/docker
./hugetlb/docker
./systemd/docker
```

- memory 서브시스템에서 docker 디렉토리를 살펴보면 다음과 같이 나온다.
```bash
csoyee@csoyee:/sys/fs/cgroup$ cd memory/docker  # go to memory subsystem

csoyee@csoyee:/sys/fs/cgroup/memory/docker$ ls  
drwxr-xr-x 2 root root 0  4월  9 14:17 03ece7982cfb65ab2e102af52561aec77882f51388b7e928313b08b1c937205a
-rw-r--r-- 1 root root 0  4월  9 19:51 cgroup.clone_children
--w--w--w- 1 root root 0  4월  9 19:51 cgroup.event_control
-rw-r--r-- 1 root root 0  4월  9 19:51 cgroup.procs
drwxr-xr-x 2 root root 0  4월  9 14:17 e70bc7bf18cbeb69e29fa0e371da1721394ab850ecbba3e67a23ca7ac8e77a7c
drwxr-xr-x 2 root root 0  4월  9 14:17 f474f6f63da0721de11d75470e67caa7207bdb65798629e515870572027fbd34
drwxr-xr-x 2 root root 0  4월  9 14:17 fe5d7c96535ee7f1b7e0c3d05bf4ede39c1054cbe927ec7a3e863eeb3ee3290a
.
.
.
```

- 여기서 디렉토리 이름을 살펴보면 내가 생성한 컨테이너 이름과 동일함을 알 수 있다.

```bash
csoyee@csoyee:/sys/fs/cgroup/memory/docker$ sudo docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
fe5d7c96535e        csoyee/ycsb:1.0     "/bin/bash"         6 hours ago         Up 6 hours                              ycsb4
03ece7982cfb        csoyee/ycsb:1.0     "/bin/bash"         6 hours ago         Up 6 hours                              ycsb3
f474f6f63da0        csoyee/ycsb:1.0     "/bin/bash"         6 hours ago         Up 6 hours                              ycsb2
e70bc7bf18cb        csoyee/ycsb:1.0     "/bin/bash"         6 hours ago         Up 6 hours                              ycsb1

```

- 03 으로 시작하는 디렉토리에 들어가서 memory 제한을 확인해보면 매우 크게 잡혀있는 것을 알고있다 (현재 시스템 메모리는 48GB). 즉 앞서 설명한 것과 같이 디폴트로 컨테이너를 수행하면 메모리가 제한되지 않음을 알 수 있다.
```bash
csoyee@csoyee:/.../03...$ cat memory.limit_in_bytes 
9223372036854771712
```

- 메모리 뿐 아니라 cpu 도 확인해보면 현재 시스템이 8개의 cpu 를 쓰고있는데 8개 cpu 모두 사용 가능한 상태이다. 

```bash
$ cat cpuset.cpus  # cpuset subsystem
0-7
```

---

이제 본격적으로 `docker run` 시에 리소스를 제한하는 법을 알아보자

## Memory

### Limit a container's access to memory

- 도커는 hard memory limit을 통해서 컨테이너가 절대로 유저 혹은 시스템 메모리로 그 이상을 사용할 수 없도록 제한하거나, soft limit 을 통해서 메모리가 부족하거나 contention 이 발생하지 않는한 컨테이너가 사용할 수 있는 메모리를 제한할 수 있다. 
- 대부분의 옵션들은 양수값을 인자로 가지며 단위로 `b`, `k`, `m`, `g` (bytes, kilobytes, megabytes, gigabytes) 가 따라온다.

많이 사용할 것 같은 옵션들만 정리해보면 아래와 같다 ([참조](https://docs.docker.com/config/containers/resource_constraints/#limit-a-containers-access-to-memory)): 
```bash
-m or --memory 
    : 사용 가능한 최대 메모리 용량. 최솟값은 4m (4 megabyte) 이다.
--kernel-memory
    : 사용 가능한 커널 메모리의 최대 용량. 최솟값은 4M 이다. kernel memory 는 스와핑 되지 않기 때문에 kernel memory 가 부족해지면 호스트 머신 자원을 막을 수 있다. 
--oom-kill-disable
    : 기본적으로 만일 OOM error 이 발생하면 커널은 컨테이너에 있는 프로세스들을 죽인다. 하지만 해당 옵션을 통해서 이를 막는다.
      단 해당 옵션은 -m/--memory 옵션이 세팅되어있는 경우에만 제대로 동작한다. 메모리 제한이 없으면 kernel 에서 메모리 확보를 위해 컨테이너 프로세스를 죽일 수 있다.

```

- 실제로 `-m` 옵션을 통해서 메모리를 제한한 후에 cgroup memory limit 을 조회하면 아래와 같이 반영되는 것을 알 수 있다. 


```bash
$ sudo docker container run -d -it -m 12g --name ycsb-test csoyee/ycsb:1.0
$ cd /sys/fs/cgroup/memory/docker/[container io]
$ cat memory.limit_in_bytes
12884901888
```


## CPU

### Configure the default CFS Scheduler 
- CFS 는 리눅스 커널의 CPU 스케줄러로 일반적인 리눅스 프로세스들을 스케줄링한다. 해당 세팅을 통해 도커는 컨테이너의 cgroup 세팅을 조절할 수 있다..

이 역시 주로 사용자들이 바꾸는 값을 위주로 정리한다:
```bash
--cpus=<value>
    : 컨테이너가 사용할 수 있는 cpu 자원을 제한다. 예를 들어서 2개의 CPU 가 있고 --cpu="1.5" 로 세팅하면 컨테이너는 최대 CPU 를 한 개 반만 사용할 수 있다. 
      해당 옵션은 도커 버전 1.13 이상에서만 사용이 가능하다. 그 전의 버전에서는 cpu-period, cpu-quota 를 통해서 조절했으나 본 문서에서는 생략한다.
--cpuset-cpus: 특정 CPU 만 사용할 수 있도록 한다. 예를 들어 0-3 이면 4개의 CPU만 사용할 수 있고 1,3 이면 2개의 CPU 만 사용가능하다.
```


- 위 옵션도 한 번 사용해보자 `--cpuset-cpus` 옵션을 통해서 사용 가능한 cpu 를 0-3 으로 제한해보았다. 

```bash
$ sudo docker stop ycsb-test
$ sudo docker container run -rm -d -it -m 12g --cpuset-cpus --name ycsb-test csoyee/ycsb:1.0
$ cd /sys/fs/cgroup/cpuset/docker/[container io]
$ cat cpuset.cpus
0-3
```

이 위에 multi-threaded compaction 을 사용하는 rocksdb application 을 돌려보면 아래와 같이 잘 동작하는 것을 알 수 있다.


#### No Limit
![image](https://user-images.githubusercontent.com/18457707/78976347-f10d4400-7b50-11ea-8052-2332e990ceac.png)

```bash
$ cat cpuacct.usage_all
cpu user system
0 31403302464 0
1 28067164270 0
2 27798598306 0
3 29354260197 0
4 29348922832 0
5 30193864066 0
6 43280119331 0
7 30666125168 0
```


#### Limit 0-3:
![image](https://user-images.githubusercontent.com/18457707/78976180-9e338c80-7b50-11ea-9cf3-5298e1232230.png)

```bash
$ cat cpuacct.usage_all
cpu user system
0 62669281445 0
1 65407853440 0
2 60252122951 0
3 61348815668 0
4 169870022 0
5 29332734 0
6 57316721835 0
7 95388125 0
```




이외에 realtime scheduler 을 사용할수도 있으나 크게 사용하는 것 같지 않아 넘어간다. 자세한 내용은 [docker manual](https://docs.docker.com/config/containers/resource_constraints/#configure-the-realtime-scheduler) 을 참조하면 된다.

