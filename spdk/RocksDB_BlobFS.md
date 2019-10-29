# BlobFS Getting Started Guide RocksDB Integration

[참고링크](https://spdk.io/doc/blobfs.html)

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

