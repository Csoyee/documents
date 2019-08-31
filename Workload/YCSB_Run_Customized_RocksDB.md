# Running Customized RockSDB 


현재 YCSB 에서 rocksdb 를 사용할 때는 $YCSB_HOME/pom.xml 에 명시된 rocksdb version 에 따라서 jni package 를 org.rocksdb 에서 받아와서 사용한다.   
관련 코드 참조: `$YCSB_HOME/pom.xml`, `$YCSB_HOME/rocksdb/pom.xml`  

하지만 만일 **내가 컴파일한 rocksdb version** 을 사용하고자 한다면 아래의 과정을 따라하면 된다.


## RocksDB jni package 만들기
### Rocksdb 소스코드 받아오기
```bash
$> git clone https://github.com/facebook/rocksdb.git
$> cd rocksdb 
# 이후 원하는 version이 있다면 해당 브랜치로 checkout 한다.
```

### Rocksdb 자바 컴파일
```bash
# -j8 은 컴파일 시 사용할 코어 개수
$> make rocksdbjavastaticrelease -j8
```
위의 명령을 치면 아래와 같은 에러가 발생할 것이다.     

> 1. vagrant 명령이 없다는 에러가 뜸: cross-platform 을 위한 명령어 
> 2. *jnilib 파일이 없다는 에러가 뜸: mac os platform을 위한 것

위의 에러는 모두 cross-platform을 위한 것이기 때문에 우리에게 필요한 명령어가 아니다.
따라서 성공적인 컴파일을 위해서는 에러를 유발하는 코드를 주석처리 해야한다.

즉, `MakeFile` 의 rocksdbjavastatic 명령을 아래와 같이 수정한다.
```bash
rocksdbjavastaticrelease: rocksdbjavastatic
  #cd java/crossbuild && vagrant destroy -f && vagrant up linux32 && vagrant halt linux32 && vagrant up linux64 && vagrant halt linux64
  cd java;jar -cf target/$(ROCKSDB_JAR_ALL) HISTORY*.md
  cd java/target;jar -uf $(ROCKSDB_JAR_ALL) librocksdbjni-*.so #librocksdbjni-*.jnilib
  cd java/target/classes;jar -uf ../$(ROCKSDB_JAR_ALL) org/rocksdb/*./class org/rocksdb/util/*.class
```

`MakeFile` 수정 후 다시 컴파일하면 jni 파일이 만들어진 것을 확인할 수 있다.
```bash
$> make rocksdbjavastaticrelease -j8
$> find -name rocksdbjni*
./java/target/rocksdbjni-5.16.0-sources.jar
./java/target/rocksdbjni-5.16.0-linux64.jar
./java/target/rocksdbjni-5.16.0.jar
./java/target/rocksdbjni-5.16.0-javadoc.jar
```
위의 4개 파일 중 우리가 사용할 것은 `./java/target/rocksdbjni-5.16.0.jar` 이다.


## YCSB 돌리기 
### YCSB 다운로드 받기
```bash
$> git clone https://github.com/brianfrankcooper/YCSB
```

### load script 수행하기
**이 때, 컴파일 시에 꼭 ycsb.sh 를 사용한다.**
아래의 load script를 수행하면 에러가 발생할 것이다.
```bash
$> bin/ycsb.sh load rocksdb -s -P workloads/workloada -p rocksdb.dir=[rocksdb directory]
```
모두 core dependency 파일이 없기 때문이다. `$YCSB_HOME/core/pom.xml` 에서 htrace와 hdrhistogram에 대한 dependency 코드를  `$YCSB_HOME/rocksdb/pom.xml` 의 dependencies 파위에 적어준다. [참조](https://github.com/Csoyee/YCSB/commit/0419da58e1d6936970f548bfb34a23024bc90e10)

그리고 나서 명령을 다시 수행하면 컴파일이 된다.
```bash
$> bin/ycsb.sh load rocksdb -s -P workloads/workloada -p rocksdb.dir=[rocksdb directory]
```
하지만 rocksdb directory 에서 버전을 확인하면 모두 5.11.3 일 것이다. 이는 `$YCSB_HOME/pom.xml` 에 명시된 버전이 5.11.3 이기 때문이다.

### 버전 바꿔 수행하기
먼저 이전에 컴파일된 내용을 모두 clean 해준다. (클린 안해주면 계속 5.11.3 다시 생성해서 사용한다.)
```bash
$> mvn -pl com.yahoo.ycsb:rocksdb-binding -am clean package
```

그 후 `$YCSB_HOME/rocksdb/target/dependency` 에 있는 `rocksdbjni-5.11.3.jar` 파일을 지우고 내가 컴파일한 버전의 jni 패키지(`rocksdbjni-5.16.0.jar`)를 위치시킨다. 

이 후, 다시 load 하고 확인하면 version 이 바뀌어있다.

