# linux-ftool


리눅스에서 buffered IO 를 수행할 때에 리눅스 페이지캐시 에 최신 접근한 데이터를 캐싱한다. `/proc/meminfo` 나 `cgroupfs` 등에서 process status 등을 보면 메모리를 어떻게 사용하는지 대략적인 정보를 볼 수 있지만 파일 별로 파일의 데이터가 얼마나 버퍼링 되어있는지는 알기가 어렵다.
본 툴 `linux-ftool` 은 특정 파일의 데이터가 리눅스 페이지캐시 상에 존재하는지 전체 파일 데이터의 몇 % (몇 개의 페이지)가 존재하는지 등을 보여준다.


## Install

```bash
$ git clone https://github.com/yazgoo/linux-ftools.git
$ cd linux-ftools
$ ./configure
$ make
$ sudo make install
```

- `make` 나 `./configure` 시에 에러가 발생한다면 autoconfig 먼저 해준다.

```bash
# cwd = /path/linux-ftools/
$ aclocal
$ automake
$ autoconf

$ ./configure
$ make
$ sudo make install
```

## Usage

```bash
$ linux-fincore [target filename]

# 한 번에 여러 파일을 타겟으로 설정할 수 있으며, 동일 디렉토리의 모든 파일들에 대한 정보를 알고싶으면 아래와 같이 하자
$ linux-fincore /target/directory/*
```

- 이에 대한 결과 값은 다음과 같은 포멧으로 나온다.

```bash
filename       size        total_pages    min_cached page    cached_pages     cached_size        cached_perc
--------       ----        -----------    ---------------    ------------     -----------        -----------
009212.sst     67331218    16439          1                  1264             5177344               7.69
```

- 위의 결과를 해석하면 009212.sst 라는 파일의 로지컬 사이즈는 64메가 정도 되고 이를 페이지 단위로 환산하면 16439개의 페이지로 이루어져있다. 현재 그 가운데 1264개의 페이지 즉 전체 페이지의 7.69% 가 캐싱된 상태임을 나타낸다.

### Options

```bash
$ linux-fincore --help

  -s --summarize          When comparing multiple files, print a summary report 
  -p --pages              Print pages that are cached
  -o --only-cached        Only print stats for files that are actually in cache. # 만일 타겟 파일이 캐싱되어있지 않으면 아무것도 나오지 않는다.
  -g --graph              Print a visual graph of each file's cached page distribution.
  -S --min-size           Require that each files size be larger than N bytes.
  -C --min-cached-size    Require that each files cached size be larger than N bytes.
  -P --min-perc-cached    Require percentage of a file that must be cached.
  -h --help               Print this message.
  -L --vertical           Print the output of this script vertically.
```
