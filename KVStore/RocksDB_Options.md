# Setup Options and Basic Tuning 
[참조](https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning)

## Block Cache Size

압축되지 않은 데이터를 캐싱하기 위해서 선택적으로 block cache 를 생성할 수 있다. 

사용 가능한 메모리 용량의 1/3 정도 사용하는 것을 권장하며 남은 free memory 는 OS page cache로 남을 것이다. OS page cache로 memory 를 많이 남겨놓는 것이 타이트한 메모리 할당을 피하는데 좋다.

## Bloom Filters

유저가 사용하는 Query 패턴에 맞추어 bloom filter 을 사용 가능하도록 할 수 있다. 만일 point lookup operation을 많이 사용하는 경우 bloom filter 을 사용함으로써 operation을 speed up 할 수 있다. 
만일 대부분의 operation 이 range scan 이라면 bloom filter이 큰 도움이 되지 않을 수도 있다. 

## SST File Manager

만일 flash storage 를 사용한다면 WAF 를 개선하기 위해서 file system mount 시에 `discard` flag 와 함께 mount 하는 것이 좋다.

만일 flash storage를 사용하고 있고 `discard` flag 를 사용하면 trimming 이 수행된다. Trimming 은 trim size가 긴 경우 긴 I/O latency를 일시적으로 유발할 수 있다. SST 파일 매니저는 file deletion speed 를 저장함으로써 trim 사이즈를 관리할 수 있다.

## Other General Options 

아래에는 일반적인 워크로드에 대하여 합리적인 out-of-box performance를 달성할 수 있는 여러 옵션들이 있다. 
```bash
cf_options.level_compaction_dynamic_level_bytes = true;
options.max_background_compactions = 4;
options.max_background_flushes = 2;
options.bytes_per_sync = 1048576;
options.compaction_pri = kMinOverlappingRatio;
table_options.block_size = 16 * 1024;
table_options.cache_index_and_filter_blocks = true;
table_options.pin_l0_filter_and_index_blocks_in_cache = true;
```

---

# RocksDB Tuning Guide

## Parallelism option
LSM architecture은 크게 두 개의 백그라운드 프로세스(: flush and compaction)를 사용한다. 두 프로세스 모두 thread를 통해 동시에 수행될 수 있다. Flush thread는 높은 우선순위를 가지는 반면 compoaction thread는 낮은 우선순위를 가진다. 각각의 pool 에서 thread 개수를 늘리기 위해서는 아래와 같이 세팅하면 된다.
```bash
options.env->setBackgroundThreads(num_threads, Env::Priority::HIGH);   // flush
options env->setBackgroundThreads(num_threads, Env::Priority::LOW);    // comapction
```
여러 스레드를 사용하기 위해서는 아래의 옵션을 수정해야한다.
#### max_background_compactions
- 동시에 수행 가능한 background compaction thread 의 개수
#### max_background_flushes
- concurrent flush operation의 개수. 일반적으로 1만으로 충분하다. 


## General options
#### allow_os_buffer
- 만일 false 이면 OS cache 에 파일을 버퍼링하지 않는다. 

#### max_open_files
- RocksDB는 모든 file descriptor 을 테이블 캐시에 저장한다. 만일 file descriptor 이 `max_open_file` 을 넘어가면 몇몇 파일들이 테이블 캐시에서 evict 되고 file descriptor 들이 닫힌다.
- 이는 read 를 위해서 table cache 를 접근해야함을 의미한다. `max_open_files` 를 -1로 설정하면 모든 파일을 open 해두기 때문에 table cache call 을 피할 수 있따.

#### block_size
- RocksDB 는 사용자 데이터를 블록에 넣는다. key-value pair 을 테이블 파일에서 읽으면 모든 블록이 memory 로 로딩된다. Default 블록 사이즈는 4KB 이며 각각의 데이블 파일은 모든 블록에 대한 index 를 저장한다. 즉 `block_size` 를 늘리는 것은 index 가 더 적은 엔트리를 보유함을 의미하기 때문에 더 작음을 의미한다. 따라서 `block_size`를 줄이는 것은 메모리 사용량과 space smplification을 줄일 수 있음을 의미한다. (하지만 read amplification을 늘린다.)

