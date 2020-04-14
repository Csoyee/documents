# FileBench Application Emulation

[reference](https://www.usenix.org/system/files/login/articles/login_spring16_02_tarasov.pdf)


## Index
- [filebench WML: how to interprete workload file](https://github.com/Csoyee/documents/blob/master/Workload/FileBench_Application_emultations.md#filebench-workload-model-language-wml)
- [sample application list](https://github.com/Csoyee/documents/blob/master/Workload/FileBench_Application_emultations.md#emulated-application-list)
- [run filebench](https://github.com/Csoyee/documents/blob/master/Workload/FileBench_Application_emultations.md#run-filebench)

---

## Filebench Workload Model Language (WML)

[파일 벤치 깃허브](https://github.com/filebench/filebench)에 가면 workload 디렉토리에 미리 정의된 워크로드 파일들이 .f 형태로 있는 것을 볼 수 있다. 이러한 워크로드에 대한 WML 를 살펴보자. 워크로드 수행 관련 command 는 크게 4개로 나눠진다; 1) processes, 2) threads, 3) flowops (operations), 4) variables; 


### Commands

#### variables

파일 벤치에 정의된 변수들을 보자. directory, 파일 개수, 파일 사이즈, 쓰레드 개수 등이 정의되어 있으며 이 값들을 추후에 process, thread, file operation 을 정의할 때에 사용한다. 파일 벤치는 기본적으로 1000개의 파일을 사용하며 각각의 파일은 편차가 있지만 16K 사이즈를 가지는 것을 알 수 있다.

```
set $dir=/tmp
set $nfiles=1000
set $meandirwidth=1000000
set $filesize=cvar(type=cvar-gamma,parameters=mean:16384;gamma:1.5)
set $nthreads=16
set $iosize=1m
set $meanappendsize=16k
```

#### run

파일 벤치를 시작한다는 의미로 정의된 `fileset` 및 fork 작업을 수행한다. 디폴트 수행 시간은 1분이다.

```bash
run [<runtime>]
```

#### define fileset

워크로드 관련된 파일 그룹에 대한 정보가 `fileset` entity 에 담겨있다. 예시로 varmail 워크로드를 보자. 

```
define fileset name=bigfileset,path=$dir,size=$filesize,entries=$nfiles,dirwidth=$meandirwidth,prealloc=80
```
위에서 `define fileset` 을 통해 파일의 이름, 디렉토리, 파일의 크기 등을 정의함을 알 수 있다. 명시적인 인자들은 제외하고 몇몇 인자들에 대해서 알아보자

##### Attributes
- `prealloc=`, `prealloc` : 선택적으로 사용하는 인자로 실제 파일벤치 워크로드를 수행하기 전에 미리 생성해두는 파일의 비중을 의미한다. 디폴트 값은 0 이기 때문에 인자를 주지 않으면 아무런 파일이 없는 상태에서 워크로드가 시작된다. 위의 예시에서는 80으로 지정되어 전체 파일 개수의 80%를 미리 만들어둔다. 아무런 값 없이 `prealloc` 만 명시한 경우에는 100% 값을 갖는다.

- `reuse` : 선택적으로 사용하는 인자로 만일 이미 파일들이 존재하면 해당 파일셋을 그대로 사용하는 옵션이다. 해당 옵션이 명시되지 않으면 기존에 있던 관련 파일들을 지우고 시작한다. 

- `dirwidth` : 디렉토리당 생성해야하는 파일의 개수를 제한한다. 디폴트는 0로 이 경우 단일 디렉토리만 사용한다. 

#### define process 

```
define process name=filereader,instances=1
{
}
```
파일 벤치의 프로세스는 OS 프로세스를 의미하며 각 쓰레드는 한 개이상의 쓰레드들을 갖는다. 추후 설명할 `thread` 와 `flowops` 와의 관계를 보면 각 프로세스는 한 개 이상의 `thread`를 가지고 그 `thread`는 `flowops` 들로 이루어져서 그 동작 방식이 정의된다. 

##### Attributes
- `name = ` : 필수적으로 가지고 있어야 하며 프로세스의 이름을 의미한다.
- `instnaces` : 선택적으로 명시하며 디폴트 값은 1이다. 만일 2개 이상의 값을 갖는 경우에 여러 개의 프로세스가 생성되며 각각의 프로세스는 자신만의 `threads` 와 `flowops` 를 갖게된다. 

- `Threads attributtes`
  - 프로세스 당 thread 정보를 의미하며 thread 이름, 개수 등이 정의되어 있다. `memsize` 값은 초반에 thread 가 수행되면서 할당하는 메모리 영역을 의미한다. 처음에는 모두 0으로 할당해두었다가 read, write 를 위한 버퍼영역을 ㅗ사용한다. 
```
define process name=filereader,instances=1
{
  thread name=filereaderthread,memsize=10m,instances=$nthreads
}
```

#### Flowops

`flowops` 구문은 thread 가 어떤 작업을 수행하는지를 결정한다. 아래는 varmail 에 정의된 `flowops` 구문이다. flowop 이름 자체는 매우 명시적이기 때문에 보면 어떤 동작을 정의하는지 알 수 있다. 


```
    flowop deletefile name=deletefile1,filesetname=bigfileset
    flowop createfile name=createfile2,filesetname=bigfileset,fd=1
    flowop appendfilerand name=appendfilerand2,iosize=$meanappendsize,fd=1
    flowop fsync name=fsyncfile2,fd=1
    flowop closefile name=closefile2,fd=1
    flowop openfile name=openfile3,filesetname=bigfileset,fd=1
    flowop readwholefile name=readfile3,fd=1,iosize=$iosize
    flowop appendfilerand name=appendfilerand3,iosize=$meanappendsize,fd=1
    flowop fsync name=fsyncfile3,fd=1
    flowop closefile name=closefile3,fd=1
    flowop openfile name=openfile4,filesetname=bigfileset,fd=1
    flowop readwholefile name=readfile4,fd=1,iosize=$iosize
    flowop closefile name=closefile4,fd=1
```
 

## Emulated Application List
### 1. Web Server
- 간단한 웹서버 I/O activity 를 emulating 함. 
- 매 HTTP request 가 오면 웹서버는 HTML file 을 열고 읽은 후 닫는 과정 (`open-read-close`) 을 수행한다. 
- client-access 레코드를 로그 파일에 쓴다.

### 2. File Server
- 여러 사용자들이 단일 파일 서버를 사용하는 상황을 emulation 함.
- 모든 유저들은 새로운 파일을 `create-write-close` 하거나 이미 있는 파일에 `open-append-close` 하는 작업을 수행한다. 
- 또한 유저는 특정 파일을 삭제할 수도 있다. 

### 3. Mail Server (varmail)
- 유저가 메일을 받으면 `create-write-fsync` 를 통해 새로운 파일을 만든다.
- 유저가 메일을 읽을 때는 `open-read-marked as read-fsync` 과정을 거친다. (항상 새로운 파일만을 읽는 것이 아니라 이전에 읽었던 이메일을 읽기도 한다.)
- 평균 email 사이즈는 16KB, 16 threads in default.
- [코드](https://github.com/filebench/filebench/blob/master/workloads/varmail.f)

### Else
- oltp
- webproxy
- videoserver


## Run FileBench

### Generating autotool scripts

```bahs
$ libtoolize
$ aclocal
$ autoheader
$ automake --add-missing
$ autoconf
```

### Compilation and installation

```
$ ./configure
$ make
$ sudo make install
```


### Run (e.g., varmail)

- 본 예시에서는 filebench 에서 기본적으로 제공하는 varmail 워크로드를 수행하였다. 
- 기본적으로 filebench 에서는 정의된 워크로드를 그대로 사용하는 것을 권장하지 않는다. 왜냐하면 varmail 만 예시로 보더라도 1000개의 16K 파일 즉 total 16M 로 그 크기가 매우 작기 때문이다. 테스트하려는 환경이나 상황에 맞게 스케일링을 하는 것을 권장하고 있다.


```bash
$ sudo filebench -f workloads/varmail.f
Filebench Version 1.5-alpha3                                                               
0.000: Allocated 177MB of shared memory                                                    
0.001: Varmail Version 3.0 personality successfully loaded                                 
0.001: Populating and pre-allocating filesets                                              
0.002: bigfileset populated: 1000 files, avg. dir. width = 1000000, avg. dir. depth = 0.5, 0 leafdirs, 14.959MB total size
0.002: Removing bigfileset tree (if exists)                                                
0.014: Pre-allocating directories in bigfileset tree                                       
0.014: Pre-allocating files in bigfileset tree                                            
0.030: Waiting for pre-allocation to finish (in case of a parallel pre-allocation)         
0.030: Population and pre-allocation of filesets completed                                 
0.030: Starting 1 filereader instances                                                     
1.032: Running...                                                                          
61.037: Run took 60 seconds...                                                             
61.037: Per-Operation Breakdown                                                            
closefile4           1035470ops    17257ops/s   0.0mb/s    0.001ms/op [0.000ms - 0.220ms]  
readfile4            1035470ops    17257ops/s 270.1mb/s    0.012ms/op [0.001ms - 4.027ms]  
openfile4            1035470ops    17257ops/s   0.0mb/s    0.005ms/op [0.001ms - 0.713ms]  
closefile3           1035470ops    17257ops/s   0.0mb/s    0.002ms/op [0.000ms - 0.466ms]  
fsyncfile3           1035473ops    17257ops/s   0.0mb/s    0.201ms/op [0.002ms - 9.548ms]  
appendfilerand3      1035476ops    17257ops/s 134.8mb/s    0.015ms/op [0.001ms - 4.016ms]  
readfile3            1035476ops    17257ops/s 270.3mb/s    0.012ms/op [0.002ms - 4.047ms]  
openfile3            1035476ops    17257ops/s   0.0mb/s    0.005ms/op [0.001ms - 0.429ms]
closefile2           1035476ops    17257ops/s   0.0mb/s    0.002ms/op [0.001ms - 1.322ms]
fsyncfile2           1035478ops    17257ops/s   0.0mb/s    0.186ms/op [0.057ms - 9.751ms]
appendfilerand2      1035481ops    17257ops/s 134.8mb/s    0.028ms/op [0.005ms - 4.090ms]
createfile2          1035481ops    17257ops/s   0.0mb/s    0.127ms/op [0.008ms - 9.844ms]
deletefile1          1035482ops    17257ops/s   0.0mb/s    0.316ms/op [0.013ms - 6.366ms]
61.037: IO Summary: 13461179 ops 224338.637 ops/s 34514/34514 rd/wr 809.9mb/s 0.070ms/op
61.037: Shutting down processes
```

- BUG? : 그냥 `filebench -f workloads/varmail.f` 명령을 수행했을 때 `Starting 1 filereader instances` 메세지가 뜬 후 더이상 진행되지 않는 현상이 발생했다. 그래서 [filebench github issue](https://github.com/filebench/filebench/issues/60) 를 참조하여 `echo 0 > /proc/sys/kernel/randomize_va_space` command 를 수행한 후 테스트하니 정상 동작했다. (원인 파악이 필요하다)

- 실행이 끝나면 위와 같이 정의된 operation 당 ops 가 기록된다. operation 은 위에 `flowops` command 를 통해 정의된 operation 목록이다. (내가 사용한 SSD는 매우 빠른 NVMe SSD 이다)



### perf result

- perf tool 을 통해 간단히 system call 당 cpu 사용량을 확인해보면 다음과 같다. (mutex 등은 생략)
  - `sys_fsync` : 25.34
  - `sys_unlink`: 19.64
  - `sys_open`  : 15.54
  - `sys_write` : 13.14
  - `sys_read`  : 7.22
