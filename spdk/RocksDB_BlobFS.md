# BlobFS Getting Started Guide RocksDB Integration
[참고링크](https://spdk.io/doc/blobfs.html)


## BlobFS
참고 논문: SPDK: A development kit to build high performance storage applications

### Blobstore
Blobstore 은 기존의 파일시스템 대신 상위 레벨의 스토리지 서비스를 지원하는 로컬 스토리지 시스템으로 사용하도록 설계된 persistency, power-fail safe 블록 allocator 이다. 상위 레벨 서비스로는 RocksDB 와 같은 키밸류 스토어나 MYSQL 과 같은 로컬 데이터베이스 혹은 Cassandra 와 같은 분산 시스템이 될 수 있다. Blobstore 은 일반적ㅇ니 목적의 파일시스템을 위해서 설계된 것이 아니고 내부적으로 POSIX 를 준수하지도 않는다. 혼란을 피하기 위해서 파일이나 객체가 아니라 `blob` 이라는 용어를 사용한다. Blobstore 은 비동기적이고 캐싱되지 않은 병렬적인 읽기 쓰기 작업을 `blob` 이라고 불리우는 블록 디바이스의 블록 그룹에 수행할 수 있도록 설계되었다. Blob 는 일반적으로 큰 편으로 적어도 100KB 의 크기이다. 다만 항상 block size의 배수 값을 유지해야한다.

### Blobfs
Blobfs 는 blobstore 위에 설계된 간단한 파일시스템이다. BlobFS 는 현재 오직 flat 한 네임스페이스만을 제공하며 디렉토리 등을 제공하지 않는다. 파일의 이름은 각각의 blob에 xattrs 로 저장되며 이는 특정 파일을 찾는데 O(n)의 operation 을 필요로 함을 의미한다. SPDK btree 구현은 징행중이다 (2017년 논문 기준). 파일 write 는 무조건 파일의 끝에 append 하는 방식으로 이루어지며 random write 기능 역시도 추후 제공 예정이다. 현재 BlobFS 는 RocksDB 상에서만 테스팅 되고 있다.

#### BDEV
SPDK bdev 의 목적은 유저스페이스 드라이버에 읳새ㅓ 인지되는 디바이스를 추상화하고 다른 3rd party 라이브버리가 응용에 블록 서비스 인터페이스를 보여주는 것이다. SPDK application 이 사용하는 block storage 는 SPDK bdev 레이어를 통해서 제공된다. 

## Getting Started
### SPDK 다운로드 및 빌드하기 
다음 [링크](https://github.com/Csoyee/documents/blob/master/spdk/SPDK_GetStarted.md) 에서 빌드까지!!!

빌드가 잘되면 셋업을 한다.
본래 디폴트로 huge page 를 2GB 할당하지만 rocksdb 돌리기 위해서 5GB 의 메모리가 할당되어야 하므로 아래와 같이 HUGEMEM 값을 지정해서 셋업한다.

```bash
$> sudo HUGEMEM=5120 scripts/setup.sh
```
SPDK `gen_nvme.sh` 스크립트를 사용해서 configuration file 에 NVME section 을 만든다

```bash
$> scripts/gen_nvme.sh > /usr/local/etc/spdk/rocksdb.conf
```
위의 명령을 하면 rocksdb.cnf 파일에 Transport ID, traddr 등등이 쓰여진다.

테스트를 위해서 빈 blobfs 를 만든다

```bash
$> sudo test/blockfs/mkfs/mkfs /usr/local/etc/spdk/rocksdb.conf Nvme0n1
```

### Rocksdb 다운로드 및 빌드하기
그냥 RocksDB 말고 SPDK Github 의 rocksdb 레포를 다운받는다. 브랜치 이름이 spdk-v5.14.3 이어야 한다.
```bash
$> cd ..
$> git clone -b spdk-v5.14.3 https://github.com/spdk/rocksdb.git
```

`db_bench` 벤치마크 툴만 BlobFS 와 integrated 되어있기 때문에 아래 옵션으로 빌드한다.
```bash
$> cd rocksdb
$> make db_bench SPDK_DIR=path/to/spdk
```

### DB Bench 를 돌리자!

```bash
$> ./db_bench --spdk=/usr/local/etc/spdk/rocksdb.conf --spdk_bdev=Nvme0n1 --spdk_cache_size=4096
```

RocksDB-SPDK 의 경우 WAF 이 default 로 disabled... 켜고 테스트했을 때 crash 가 발생한다고 한다. (Towards Building a High-Performance, Scale-In Key-Value Storage System 논문 참조)

혹시 몰라 나는 아래의 옵션으로 수행했다.

```bash
$> ./db_bench --spdk=/usr/local/etc/spdk/rocksdb.conf --spdk_bdev=Nvme0n1 --spdk_cache_size=4096 --disable_wal=1 --use_existing_db=0
```

수행했을 때 `using bdev Nvme0n1` 이라는 메세지가 뜨고 이후 Rocksdb 및 벤치 정보가 뜬 후 다 돌면 ops, BW 정보를 확인할 수 있다.

#### 출력 예

```
using bdev Nvme0n1
Initializing RocksDB Options from the specified file
Initializing RocksDB Options from command-line flags
RocksDB:    version 5.14
Date:       Tue Oct 29 16:29:13 2019
CPU:        8 * Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz  
CPUCache:   8192 KB  
Keys:       16 bytes each   
Values:     100 bytes each (50 bytes after compression) 
Entries:    1000000  
Prefix:    0 bytes 
Keys per prefix:    0   
RawSize:    110.6 MB (estimated)   
FileSize:   62.9 MB (estimated)   
Write rate: 0 bytes/second          
Read rate: 0 ops/second             
Compression: Snappy                 
Memtablerep: skip_list
Perf Level: 1 
DB path: [/tmp/rocksdbtest-0/dbbench]
fillseq      :       0.388 micros/op 2576131 ops/sec;  285.0 MB/s
```

위의 벤치마크는 fillseq 로 1M entries (entries with 16B key and 100B value) 쓰는 간단한 벤치마크로 spdk 사용하지 않고 동일 조건으로 수행한 경우 1199111ops/sec 를 보임 (spdk 사용했을 때 2576133ops/sec 로 두 배 이상 성능 차이를 보임)


## 설치 시 유의 사항
- RocksDB branch 확인: spdk-v5.14.3 branch 로 진행 (master branch 는 제대로 동작 X)
- RocksDB make 할 때 db_bench 옵션으로 make 하기 `$> make db_bench SPDK_DIR=[spdk root dir]` 


#### RocksDB Compile 과정에서 생길 수 있는 에러 
- ZLIB 관련 함수 undefined error: zstd version 1.3 이상으로 올려주기 [링크](https://github.com/facebook/zstd)

