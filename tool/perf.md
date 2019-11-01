# Perf


Perf 는 리눅스의 성능 평가 툴로 리눅스 버전 2.6.31 버전 이후로 사용 가능하다.

## 설치

아래의 command 를 통해 설치할 수 있다.
```bash
$ sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`
```
그런데 나는 5.3.2 커널을 쓰고있는데 저렇게 수행했을 때 아래의 에러메세지가 떴다.

```bash
E: Unable to locate package linux-tools-5.3.2
E: Couldn't find any package by regex 'linux-tools-5.3.2'
```

그래서 커널 코드에서 찾아서 make 를 해주었다.   
(커널 컴파일 할 때 사실 install 되었는데 내가 실수로 지운 것 같다...:sweat_smile:)

```bash
$ cd [your/kernel/code]/tools/perf
$ sudo make
$ sudo make install
```

## 수행 

일단 가장 간단한 기록, 리포트 기능이 있다.

```bash
# 기록
$ perf record [command]

# 레포트
$ perf report
```
record 를 수행하면 `perf.data` 라는 파일이 생기고 해당 파일을 읽어서 report 를 하는 방식이다.


예시로 sqlite 상에서 androbench 를 돌려보았다.

```bash
$ perf record sqlite3 test.db < androbench_full.sql
.
.
.
[ perf record: Woken up 1 times to write data ]
[ perf record: Captured and wrote 0.274 MB perf.data (7120 samples) ]

$ perf report 
# To display the perf.data header info, please use --header/--header-only options.
#
#
# Total Lost Samples: 0
#
# Samples: 7K of event 'cycles:u'
# Event count (approx.): 729061475
#
# Overhead  Command  Shared Object       Symbol                                   
# ........  .......  ..................  .........................................
#
    17.93%  sqlite3  sqlite3             [.] sqlite3VdbeExec
    13.35%  sqlite3  sqlite3             [.] btreeParseCellPtr
     4.03%  sqlite3  sqlite3             [.] sqlite3RunParser
     2.26%  sqlite3  [unknown]           [.] 0000000000000000
     2.21%  sqlite3  sqlite3             [.] unixSync
     2.10%  sqlite3  libc-2.19.so        [.] __fdatasync_nocancel
     1.90%  sqlite3  sqlite3             [.] getCellInfo
```

이외에 mem, top, script, stat 등 다양한 command 가 있으나 나중에 쓰게 되는 경우 추가하겠다.
자세한 내용은 `$ perf --help` command 를 통해 확인할 수 있따.
