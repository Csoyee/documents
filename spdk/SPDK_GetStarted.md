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


## FIO 수행

fio 를 사용할 수 있게 configure 했다고 가정하고 예시로 제공되는 fio 플러그인을 활용해 fio 를 수행해보자. `[path/to/spdk]/exmaples/nvme` 에는 [spdk nvme bdev](https://spdk.io/doc/bdev.html) 를 활용하는 예제 코드들이 존재한다. 


```bash
LD_PRELOAD=[path to spdk repo]/build/fio/spdk_nvme fio [path to spdk repo]/examples/nvme/fio_plugin_example_config.fio
```

위의 명령을 실행하면 아마 `fio_plugin.c: 406:spdk_fio_setup: *ERROR*: Failed to find namespace 'ns=X'` 이와 같은 에러가 발생할 것이다. 

이는 NVMe device 를 선택해서 넘겨줘야 하는데 example_config 에는 설정되어 있지 않기 때문이다. 
아래 줄을 example_config.fio 에 추가해주자. 물론 traddr 값은 자신의 환경에 맞게 바꾸어주어야 한다. 

```bash
filename=trtype=PCIe traddr=0000.04.00.0 ns=1
```

위의 명령을 추가하고 다시 위의 명령으로 fio 를 수행하면 fio 가 정상적으로 수행된다.
