# FileBench Application Emulation

[reference](https://www.usenix.org/system/files/login/articles/login_spring16_02_tarasov.pdf)

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
