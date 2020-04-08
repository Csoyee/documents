# 정리 문서 
참고/정리한 문서 모아놓기

## Index

### KV Store
KV store 관련 공부자료 및 YCSB workload 수행 방법 등 정리, 주로 RocksDB 위주로 정리가 되어있다. 몇몇 자료들은 구글 프리젠테이션으로 제작되어있기 때문에 [README](https://github.com/Csoyee/documents/blob/master/KVStore/README.md) 에 있는 링크를 참조하면 된다. 
- [Running YCSB on Redis](https://github.com/Csoyee/documents/blob/master/KVStore/Redis_YCSB.md)
- [Running YCSB on RocksDB](https://github.com/Csoyee/documents/blob/master/KVStore/RocksDB_YCSB.md)
- [RocksDB WIKI](https://github.com/Csoyee/documents/tree/master/KVStore/rocksdbWIKI)

### SQLite
SQLite 공부자료 위주로 포함되어 있다. 
- [SQLite API](https://github.com/Csoyee/documents/blob/master/SQLite/SQLite_API.md)
- [SQLite Internal Overview](https://github.com/Csoyee/documents/blob/master/SQLite/SQLite_Internals.md)
- CODE: [SQLite Btree](https://github.com/Csoyee/documents/blob/master/SQLite/SQLite_Btree.md), [SQLite Pager](https://github.com/Csoyee/documents/blob/master/SQLite/SQLite_Pager.md)

### Workloads
FIO, filebench 와 같은 synthetic benchmark 및 YCSB, tpcc 와 같은 benchmark 의 사용법 등을 정리함
- [Interprete FIO](https://github.com/Csoyee/documents/blob/master/Workload/FIO_interprete.md)
- pytpcc
- tpcc-mysql
- YCSB

### Docker
Docker Study 
- [Get Docker Engine](https://github.com/Csoyee/documents/blob/master/Docker/Docker_Get_Engine.md)

### NVMe
NVMe interface 관련 내용 위주로 정리되어 있다. inteface 및 ioctl 명령을 위한 wrapper 함수를 포함한다.
- [NVMe CLI](https://github.com/Csoyee/documents/blob/master/nvme/nvme-cli.md)

### Linux Setting
실험에 필요한 정보들이 있다. 파일시스템 및 디바이스 파라미터 설정 등의 내용을 포함한다. 
- [pdflush parameter](https://github.com/Csoyee/documents/blob/master/Linux_Setting/DirtySync.md)
- [ext4 Discard Option set and test](https://github.com/Csoyee/documents/blob/master/EXT4_discard.md)
- [Set io poll mode](https://github.com/Csoyee/documents/blob/master/io_polling.md)

### Tools 
실험 및 실험 해석에 필요한 여러가지 tool 및 command 정리
- [useful commands](https://github.com/Csoyee/documents/blob/master/tool/useful_command.md)
- [ftrace](https://github.com/Csoyee/documents/blob/master/tool/ftrace.md)
- [gnuplot](https://github.com/Csoyee/documents/blob/master/tool/gnuplot.md)
- [perf](https://github.com/Csoyee/documents/blob/master/tool/perf.md)


SPDK document 내용에 대한 정리 및 설치, 사용 방법을 포함한다.
- [SPDK Getting Started](https://github.com/Csoyee/documents/blob/master/spdk/SPDK_GetStarted.md)
- [SPDK RocksDB BlobFS](https://github.com/Csoyee/documents/blob/master/spdk/RocksDB_BlobFS.md)

### OCSSD
Cosmos+ device 를 OCSSD 로 사용하는 방법 


### Papers
Presentaion Materials

- [In storage processing, FAST2020](https://docs.google.com/presentation/d/182ep_ZF9Ltdp8TRRpsmeEtbc6ZaSlFMRaD7FQeolUDk/edit?usp=sharing)
- [KV store related materials](https://github.com/Csoyee/documents/blob/master/KVStore/README.md)
- [MultiStream, Hotstorage](https://drive.google.com/file/d/1VYWjfkaqCNCJrK-njqXkDqF_SRBGLVHS/view?usp=sharing)
