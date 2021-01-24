# SPDK Get Started

- 참고 문서: [doc](https://spdk.io/doc/getting_started.html) [github](https://github.com/spdk/spdk)
- 환경: Linux


## 소스코드 다운로드 
```bash
$ git clone https://github.com/spdk/spdk
$ cd spdk
$ git submodule update --init
```

## Prerequisite

dependencies 들을 자동으로 설치하도록 스크립트가 제공된다!
```bash
$ ./scripts/pkgdep.sh
```

## Build
Linux:
```bash
$ ./configure
$ make
```

이 때 configure 시에 다양한 옵션 등을 사용해볼 수 있는데 `./configure --help` 를 통해서 어떤 option 이 사용 가능한 지 알 수 있다.
나의 경우 fio test 를 해보고 싶어서 `--with-fio=[path/of/fio]` 옵션을 설정하여 configure 을 하였다.

> 또한 configure 과정에서 `ERROR: Libtool library used but 'LIBTOOL' is undefined` 다음과 같은 에러가 발생하였는데 해결 시 다음 링크를 참조하였다. [링크](https://hojakzeal.tistory.com/61) 원인은 매크로 파일 경로가 꼬여서 발생한 문제였다. 

## Unit Test
Build 가 끝나면 unit test 를 통해서 제대로 동작하는지 확인할 수 있다.
```bash
$ ./test/unit/unittest.sh
```

## 예시 Application 수행

SPDK application 을 수행하기 이전에
1. hugepages 가 할당되어야 하고 
2. Nvme 디바이스가 native kernel driver 에서 unbound 되어야 한다.
SPDK 는 해당 과정을 자동화 하는 스크립트를 제공한다. 이 때 모든 해당 스크립트는 *root* 권한으로 수행되어야 한다.

```bash
$ sudo scripts/setup.sh
```

device 를 다시 커널로 bind 할 때는:
```bash
$ sudo scripts/setup.sh reset 
```
명령을 통해서 수행할 수 있다. 


디폴트로 script 는 2048MB 의 hugepages 를 할당하는데 해당 숫자를 바꾸기 위해서는 HUGEMEM(in MB) 를 아래와 같이 수정하면 된다.
```bash
$ sudo HUGEMEM=4096 scripts/setup.sh
```

Setup 을 제대로 마쳤으면 `hello_word` 가 제대로 동작한다.
```bash
$ ./example/nvme/hello_world/hello_word
```

Hello world 가 제대로 동작하면 쭉 다른 메세지가 뜨다가 마지막에 `Hello world!` 가 프린트 되는 것을 확인할 수 있.


## SPDK NVMe BDEV

기존 시스템에서는 NVMe PCIe 드라이버는 system Kernel의 일부이고 application은 시스템 콜 인터페이스를 통해서 드라이버와 소통할 수 있었다. 하지만 SPDK 는 조금 다른 관점을 보인다.
SPDK는 커널로부터 NVMe device를 unbind하고 hardware queue를 [유저스페이스 NVMe driver](https://spdk.io/doc/nvme.html)로 bind한다. 이를 통해서 application은 유저 스페이스에서 바로 device queue에 접근할 수 있다.
SPDK NVMe Driver은 응용에 바로 연결된 C 라이브러리로 NVMe SSD 로/로부터 direct, zero-copy 데이터 이동을 지원한다. 별도의 쓰레드를 만들지 않고 오직 응용 프로그램이 요청하는 함수 콜에 의해 수행된다.
NVMe driver 라이브러리는 NVMe device를 제어하기 위해서 PCI BAR을 로컬 프로세스로 직접 매핑하고, MMIO를 수행한다.
SPDK NVMe driver은 비동기적으로 동작하는데 이는 드라이버가 IO 요청을 NVMe submission queue에 내리고 completion 되기 전에 바로 리턴함을 의미한다. 이러한 일반적인 흐름은 전체적으로 Linux의 libaio와 크게 다르지 않다. 응용은 완료되지 않는 I/O가 있는 queue 에서 I/O completion을 위해 폴링해야한다.



## FIO 수행

fio 를 사용할 수 있게 configure 했다고 가정하고 예시로 제공되는 fio 플러그인을 활용해 fio 를 수행해보자. `[path/to/spdk]/exmaples/nvme` 에는 [spdk nvme bdev](https://spdk.io/doc/bdev.html) 를 활용하는 예제 코드들이 존재한다. 


```bash
$> LD_PRELOAD=[path to spdk repo]/build/fio/spdk_nvme fio [path to spdk repo]/examples/nvme/fio_plugin_example_config.fio
```

위의 명령을 실행하면 아마 `fio_plugin.c: 406:spdk_fio_setup: *ERROR*: Failed to find namespace 'ns=X'` 이와 같은 에러가 발생할 것이다. 

이는 NVMe device 를 선택해서 넘겨줘야 하는데 example_config 에는 설정되어 있지 않기 때문이다. 
물론 traddr 값은 자신의 환경에 맞게 바꾸어주어야 한다. 먼저 address 정보를 확인한다.

```bash
$> <path to spdk repo>/scripts/gen_nvme.sh
{
"subsystem": "bdev",
"config": [
{
"method": "bdev_nvme_attach_controller",
"params": {
"trtype": "PCIe",
"name":"Nvme0",
"traddr":"0000:01:00.0"
}
}
]
}
```

위의 정보에 따라서 trtype과 traddr를 `exmple_config.fig` 에 추가해주면 위의 에러가 해결된다.

```bash
filename=trtype=PCIe traddr=0000.01.00.0 ns=1
```

위의 명령을 추가하고 다시 위의 명령으로 fio 를 수행하면 fio 가 정상적으로 수행된다.

```
$> LD_PRELOAD=[path to spdk repo]/build/fio/spdk_nvme fio [path to spdk repo]/examples/nvme/fio_plugin_example_config.fio
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=spdk, iodepth=128
fio-3.23-58-gea69-dirty
Starting 1 thread
[2021-01-24 20:10:24.520874] Starting SPDK v21.01-pre git sha1 f1f51f2b4 / DPDK 20.11.0 initialization...
[2021-01-24 20:10:24.520935] [ DPDK EAL parameters: [2021-01-24 20:10:24.520956] fio [2021-01-24 20:10:24.520976] --no-shconf
[2021-01-24 20:10:24.520981] -c 0x1 [2021-01-24 20:10:24.521000] -m 0 [2021-01-24 20:10:24.521006] --log-level=lib.eal:6 [2021-01-24 20:10:24.521012] --log-level=lib.cryptodev:5 [2021-01-24 20:10:24.521017] --log-level=user1:6 [2021-01-24 20:10:24.521022] --iova-mode=pa [2021-01-24 20:10:24.521026] --base-virtaddr=0x200000000000 [2021-01-24 20:10:24.521031] --match-allocations [2021-01-24 20:10:24.521036] --file-prefix=spdk_pid4112 [2021-01-24 20:10:24.521041] ]
EAL: No available hugepages reported in hugepages-1048576kB
EAL: No legacy callbacks, legacy socket not created
Jobs: 1 (f=1)
test: (groupid=0, jobs=1): err= 0: pid=4125: Sun Jan 24 20:10:27 2021
  read: IOPS=47.9k, BW=187MiB/s (196MB/s)(375MiB/2002msec)
    slat (nsec): min=86, max=14179, avg=101.15, stdev=106.33
    clat (usec): min=212, max=2101, avg=1019.42, stdev=115.43
     lat (usec): min=212, max=2101, avg=1019.52, stdev=115.43
    clat percentiles (usec):
     |  1.00th=[  807],  5.00th=[  840], 10.00th=[  873], 20.00th=[  914],
     | 30.00th=[  955], 40.00th=[  988], 50.00th=[ 1020], 60.00th=[ 1045],
     | 70.00th=[ 1074], 80.00th=[ 1106], 90.00th=[ 1172], 95.00th=[ 1221],
     | 99.00th=[ 1303], 99.50th=[ 1336], 99.90th=[ 1385], 99.95th=[ 1418],
     | 99.99th=[ 1876]
   bw (  KiB/s): min=190904, max=192512, per=100.00%, avg=191826.00, stdev=670.74, samples=4
   iops        : min=47726, max=48128, avg=47956.50, stdev=167.69, samples=4
  write: IOPS=47.8k, BW=187MiB/s (196MB/s)(374MiB/2002msec); 0 zone resets
    slat (nsec): min=97, max=13130, avg=219.33, stdev=124.99
    clat (usec): min=201, max=2764, avg=1652.25, stdev=357.28
     lat (usec): min=202, max=2764, avg=1652.47, stdev=357.28
    clat percentiles (usec):
     |  1.00th=[ 1123],  5.00th=[ 1156], 10.00th=[ 1205], 20.00th=[ 1303],
     | 30.00th=[ 1401], 40.00th=[ 1500], 50.00th=[ 1614], 60.00th=[ 1729],
     | 70.00th=[ 1860], 80.00th=[ 2008], 90.00th=[ 2180], 95.00th=[ 2278],
     | 99.00th=[ 2442], 99.50th=[ 2474], 99.90th=[ 2606], 99.95th=[ 2638],
     | 99.99th=[ 2671]
   bw (  KiB/s): min=190288, max=193344, per=100.00%, avg=191354.00, stdev=1401.16, samples=4
   iops        : min=47572, max=48336, avg=47838.50, stdev=350.29, samples=4
  lat (usec)   : 250=0.01%, 500=0.01%, 750=0.03%, 1000=22.14%
  lat (msec)   : 2=67.80%, 4=10.01%
  cpu          : usr=100.05%, sys=0.00%, ctx=3, majf=0, minf=0
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=95963,95754,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=187MiB/s (196MB/s), 187MiB/s-187MiB/s (196MB/s-196MB/s), io=375MiB (393MB), run=2002-2002msec
  WRITE: bw=187MiB/s (196MB/s), 187MiB/s-187MiB/s (196MB/s-196MB/s), io=374MiB (392MB), run=2002-2002msec
```
