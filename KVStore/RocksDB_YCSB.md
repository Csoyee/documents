# Running YCSB on Rocksdb
[Reference](https://github.com/brianfrankcooper/YCSB/tree/master/rocksdb)


## YCSB 다운로드 및 compile
[참고](https://github.com/Csoyee/documents/blob/master/Workload/YCSB_How_To_Start.md)

```bash
$ git clone https://github.com/brianfrankcooper/YCSB
$ cd YCSB
$ mvn clean package
```
    
## 데이터 로딩 및 run 

```bash
# Load  
$ ./bin/ycsb load rocksdb -s -P workloads/workloada -p rocksdb.dir=/tmp/ycsb-rocksdb-data
# Run   
$ ./bin/ycsb run rocksdb -s -P workloads/workloada -p rocksdb.dir=/tmp/ycsb-rocksdb-data      
```

## Rocksdb configuration  
- rocksdb.dir (required): Rocksdb 데이터 파일이 위치할 디렉토리를 configuration으로 지정해준다. 


## Option 조정하기
- rocksdb 의 경우 configuration을 parameter로 조정하도록 되어있지 않기 때문에 Client에서 option을 조정하거나 parameter을 지정해주는 인터페이스는를 추가해주어야 한다. 

## Rocksdb Version 조정하기
- YCSB root 디렉토리에서 pom.xml 에 지정된 rocksdb.version 변수 수정


## Configuration 추가하기 
[참고 링크 - compaction thread 개수 option 조정](https://github.com/Csoyee/YCSB/commit/c04863a2035e763c6b6751ec0b5034db93075a40)
- rocksdb/src/main/java/com/yahoo/ycsb/db/rocksdb/RocksDBClient.java 파일에서 property 받는 코드를 추가합니다.
- 아래 예제는 `-p rocksdb.comp=(bg compaction thread 개수)` 옵션을 통해 rocksdb 백그라운드 compaction thread 개수를 조정하는 코드이다.
1. property 이름 추가하기  
    > `static final String PROPERTY_ROCKSDB_COMP_THREAD = rocksdb.comp]`
2. getProperty 함수를 이용해서 option 받기  
    > `String compThreadString = getProperties().getProperty(PROPERTY_ROCKSDB_COMP_THREAD)`  
    - 만일 받고자하는 인자가 integer 이면,   
    `import java.lang.Integer.*;` 로 인자 임포트하고   
    `int compThread = Integer.parseInt(compThreadString)` 으로 integer 값 받아옴.
    
