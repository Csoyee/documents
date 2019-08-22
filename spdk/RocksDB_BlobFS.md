# BlobFS Getting Started Guide RocksDB Integration

[참고링크](https://spdk.io/doc/blobfs.html)


## 설치 시 유의 사항
- RocksDB branch 확인: spdk-v5.14.3 branch 로 진행 (master branch 는 제대로 동작 X)
- RocksDB make 할 때 db_bench 옵션으로 make 하기 `$> make db_bench SPDK_DIR=[spdk root dir]` 


#### RocksDB Compile 과정에서 생길 수 있는 에러 
- ZLIB 관련 함수 undefined error: zstd version 1.3 이상으로 올려주기 [링크](https://github.com/facebook/zstd)
