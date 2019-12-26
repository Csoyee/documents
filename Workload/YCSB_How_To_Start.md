# Getting Started 
[Reference](https://github.com/brianfrankcooper/YCSB)

## Prerequisite
### 자바 (>= 8) 
```bash
$ sudo apt-get install openjdk-8-jdk  # openjdk-[9/10/11]-jdk 다 가능
```
- 만일 openjdk 버전 8이상을 설치할 수 없으면 아래와 같이 한 다음에 install 
```bash
$ sudo add-apt-repository ppa:openjdk-r/ppa
$ sudo apt-get update 
```

### Maven (>= 3.1)
- YCSB는 Maven3 version  을 필요로 함. (Maven2를 사용할 경우 [다음](https://github.com/brianfrankcooper/YCSB/issues/406)과 같은 에러 발생)
```bash
$ sudo apt-get install maven
$ mvn --version
```
- 만일 설치된 maven 버전이 3.1 미만이면 아래와 같이 설치
```bash
$ sudo add-apt-repository ppa:andrei-pozolotin/maven3
$ sudo apt-get update
$ sudo apt-get install maven3
```

## Download
```bash
$ git clone https://github.com/brianfrankcooper/YCSB
```

## Compile
- 각각의 데이터베이스 바인딩 디렉토리 아래에 README 파일에 컴파일 방법이 명시되어 있음  
```bash
# e.g., Redis compile  
$ mvn -pl com.yahoo.ycsb:redis-binding -am clean package
# 일반적으로는 아래의 명령으로 가능
$ mvn clean package
```

## Run
- loading
```bash
$ bin/ycsb.sh load (dbname) -P (workload name)
```
- run 
```bash
$ bin/ycsb.sh run (dbname) -P (workload name)
```
