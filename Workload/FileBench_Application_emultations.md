# FileBench Application Emulation

[reference](https://www.usenix.org/system/files/login/articles/login_spring16_02_tarasov.pdf)


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
