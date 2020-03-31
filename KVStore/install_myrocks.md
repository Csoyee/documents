# Install MyRocks


Reference: [MyRocks Home Page](http://myrocks.io/docs/getting-started/)



## Getting Started

### Prerequisites

```bash
$ sudo apt-get update
$ sudo apt-get install g++ cmake libbz2-dev libaio-dev bison \
  zlib1g-dev libsnappy-dev libgflags-dev libreadline6-dev libncurses5-dev \
  libssl-dev liblz4-dev libboost-dev gdb git
```

### Set up Git Repository

```bash
$ git clone https://github.com/facebook/mysql-5.6.git
$ cd mysql-5.6
$ git submodule init
$ git submodule update
$ cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SSL=system \
  -DWITH_ZLIB=bundled -DMYSQL_MAINTAINER_MODE=0 -DENABLED_LOCAL_INFILE=1 \
  -DENABLE_DTRACE=0 -DCMAKE_CXX_FLAGS="-march=native"
$ make -j8
```


### Error Handling

#### ZSTD Not found
- [해당 레포](https://github.com/facebook/zstd) 에서 ZSTD 라이브러리 설치

#### LZ4F Not found
- [해당 레포](https://github.com/lz4/lz4) 에서 LZ4 라이브러리 설치

