# Running YCSB on Rocksdb
[Reference](https://github.com/brianfrankcooper/YCSB/tree/master/rocksdb)


## YCSB 다운로드 및 compile
[참고](https://github.com/Csoyee/documents/blob/master/Workload/YCSB_How_To_Start.md)

```bash
$ git clone https://github.com/brianfrankcooper/YCSB
$ cd YCSB
$ mvn clean package
```
- 이 때 `mvn clean package` 명령은 YCSB 에서 제공하는 모든 디비에 대한 워크로드를 컴파일하는 명령이다(따라서 시간이 엄.청 오래걸린다) . 단일 워크로드만 컴파일하기 위해서는 YCSB 의 readme 파일에 명시된 대로 binding 할 데이터베이스를 지정해주면 된다.
    
## 데이터 로딩 및 run 

```bash
# Load  
$ ./bin/ycsb load rocksdb -s -P workloads/workloada -p rocksdb.dir=/tmp/ycsb-rocksdb-data
# Run   
$ ./bin/ycsb run rocksdb -s -P workloads/workloada -p rocksdb.dir=/tmp/ycsb-rocksdb-data      
```


## RocksDB Configuration 

- `rocksdb.dir` (required): RocksDB 데이터 파일이 위치할 디렉토리를 명시한다.(위의 예시 참조)
- `rocksdb.optionsfile` - RocksDB option file 경로를 명시한다. 자세한 설명은 뒷 부분을 참조하면 된다. 


## RocksDB Options and Option File 

### RocksDB Options File Format
- 락스디비 옵션 파일은 [INI file](https://en.wikipedia.org/wiki/INI_file) 포맷을 따른다. 
- 각 RocksDB option 파일은 4개의 섹션을 가진다. `Version` section, `DBOptions` section, `CFOptions` section, 그리고 `TableOptions` section이 있다. 자세한 예시는 다음 [예시 파일](https://github.com/facebook/rocksdb/blob/master/examples/rocksdb_option_file_example.ini)을 참조하면 된다.
- .ini 파일을 만든 후에 rocksdb 옵션으로 `rocksdb.optionsfile` 에 대한 파일 경로를 추가하면 옵션이 적용된다. 옵션 적용이 제대로 됐는지는 rocksdb log file 을 통해서 확인할 수 있다.

### Ignoring unknown options 
- RocksDB 버전이 증가함에 따라 몇몇 옵션들이 추가되었다. 이에 이전 버전의 RocksDB 는 나중 버전의 RocksDB에 있는 옵션을 인지하지 못하는 경우가 생긴다. 이 경우 버그가 발생하는 것을 막기 위해서 `ignore_unknown_options` 플래그를 추가한다. (디폴트 옵션은 false 이다)

---

## Old version ...
:warning: 이 아래는 YCSB 이전 버전 (2018) 관련 내용으로 2019년 이후로 일부 수정되었다. 


### Option 조정하기
- rocksdb 의 경우 configuration을 parameter로 조정하도록 되어있지 않기 때문에 Client에서 option을 조정하거나 parameter을 지정해주는 인터페이스는를 추가해주어야 한다. 

### Rocksdb Version 조정하기
- YCSB root 디렉토리에서 pom.xml 에 지정된 rocksdb.version 변수 수정


### Configuration 추가하기 
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
    
