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


## 설치 시 유의 사항
- RocksDB branch 확인: spdk-v5.14.3 branch 로 진행 (master branch 는 제대로 동작 X)
- RocksDB make 할 때 db_bench 옵션으로 make 하기 `$> make db_bench SPDK_DIR=[spdk root dir]` 


#### RocksDB Compile 과정에서 생길 수 있는 에러 
- ZLIB 관련 함수 undefined error: zstd version 1.3 이상으로 올려주기 [링크](https://github.com/facebook/zstd)

