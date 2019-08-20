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

## Flusing options
Rocksdb 로 내려오는 모든 write 명령은 우선 in-memory 데이터 구조인 memtable에 삽입된다. 일단 active memtable이 꽉 차면 새로운 memtable을 만들고 old memtable을 read-only 로 만든다. RocksDB에서 해당 memtable을 __immutable__ 하다고 부르며 항상 한 시점에는 하나의 active memtable이 있다. Immutable memtable은 storage 로 flush 될 때까지 대기하며 flush 방법을 조정하기 위한 3가지 옵션이 있다.

#### write_buffer_size
단일 memtable 사이즈를 결정한다. Memtable 사이즈가 해당 사이즈를 초과하게 되면 immutable memtable으로 변경되고 새로운 memtable이 생성된다.

#### max_write_buffer_number
Memtable의 최대 개수를 결정한다. 만일 active memtable이 꽉찼는데 memtable의 개수가 max_write_buffer_number 을 넘어가면 이후 내려오는 write 를 stall 한다. 이는 flush 가 write 속도보다 느린 경우 발생한다.

#### min_write_buffer_number_to_merge
Memtable 이 storage 로 flush 되기 이전에 merge 하는 최소의 memtable 개수를 의미한다. 예를 들어서, 만일 해당 옵션이 2로 세팅되어 있으면 immuable memtable 은 2개 이상이 있어야만 flush가 가능하다. 단일 immutable tableㅇ느 절대로 플러시되지 않는다. 만일 여러개의 memtable이 merge 되면 storage에 (중복 update 가 하나의 key 로 merge 되기 때문에) 더 적은 데이터가 쓰여지게 된다. 하지만 Get() 을 수행할 때 모든 memtable 을 traverse 해야하기 때문에 본 옵션을 높게 설정하면 read performance 를 해칠 수 있다. 

## Level Style Compaction
Level style compaction에서 데이터베이스 파일은 level 형태로 구성되어 있다. Memtable 은 level0로 플러쉬되고 가장 최신의 데이터를 가지고 있다. 높은 level 의 데이터들은 더 오래된 데이터를 보유하고 있다. Level0 의 파일들은 중복된 값들을 가질 수 있으나 level1 이상의 파일들은 동일 레벨에 중복 값을 가지지 않느다. 따라서 Get()을 수행할 때 level0 에 있는 각각의 파일을 모두 체크해야한다. 하지만 하위 레벨에서는 오직 한 파일이 특정 키를 가지고 있다. 

Compaction은 level N 에서 몇개의 파일을 가져다가 levle N+1에 있는 overlapping 파일들에 컴팩트 할 것이다. 다른 레벨 혹은 다른 key ragne 들에 대한 두 개의 compaction 작업은 독립적으로 수행되며 동시에 수행될 수도 있다. 컴팩션 속도는 최대 write 속도에 비례하며 만일 compaction 이 write rte 를 따라가지 못하면 database 에 의해서 사용되는 space의 양은 갈수록 증가할 것이다. 따라서 __Compaction이 높은 병렬성을 갖지고 수행되어 storage룰 fully utilize할 수 있도록 설정하는 것은 중요하다.__

Level0, 1 compaction은 어렵다. 일반적으로 L0에서 거의 대부분의 key space를 사용하기 때문에 L0->L1 컴팩션을 할 때 compaction은 level1의 모든 파일을 포함한다. L1의 모든 파일들이 compaction 하는데 사용이 되면 L1->L2 compaction이 수행될 수 없다. (L0->L1 compaction이 끝나기를 기다려야한다). 따라서 만일 L0->L1 컴팩션이 느리게 수행되면 다른 모든 compaction 들이 수행될 수 없기 때문에 성능상 bottleneck이 될 수 있다. 

L0->L1 compaction은 항상 항상 single-threaded 로 수행된다. 하지만 single-threaded compaction 으로는 좋은 성능을 얻을 수 없다. 이로 인해 문제가 발생하는 경우 disk utilization을 체크해라. 만일 disk 가 완전히 utilized 되고 있지 않으면 compaction configuration에 문제가 있음을 알 수 있다. L0->L1 속도를 빠르게 유지하기 위해서는 level0 파일의 사이즈를 level1 파일 사이즈와 동일하게 조정하는 것을 추천한다. 

#### level0_file_num_compaction_trigger
level0 이 해당 값에 도달하면 L0->L1 compaction이 불린다. 이를 통해 level0 의 사이즈가 `write_buffer_size * min_write_buffer_number_to_merge * level0_file_num_compaction_trigger` 값임 정도 될 것이라고 예측할 수 있따.

#### max_bytes_for_level_base / max_bytes_for_level_multiplier
`max_bytes_for_level_base`는 레벨1 의 총 사이즈이다. 언급된 바와 같이 level0 와 동일 사이즈로 설정하는 것을 추천한다. 각각의 하위 레벨은 그 이전 레벨에 `max_bytes_for_level_multiplier`의 값을 곱한 만큼의 사이즈를 갖는다. multiplier의 경우 default 값이 10이며 해당 값을 바꾸지 않는 것을 추천한다.

#### target_file_size_base / target_file_size_multiplier
level1의 파일들은 `target_file_size_base` bytes의 파일 사이즈를 갖는다. 각각의 하위 파일 사이즈는 이전 level 에 `target_file_size_multiplier` 만큼 곱한 사이즈의 파일을 갖는다. Multiplier의 default 값은 1이다. 따라서 모든 SST 파일들은 default configuration 상황에서 동일한 파일 사이즈를 갖는다. `target_file_size_base` 를 줄이는 것은 총 파일 개수를 줄일 수 있기 때문에 좋다. 일반적으로 level 1에 10개의 파일이 들어갈 수 있도록 설정하는 것을 추천한다.


### num_levels
default 값은 7이다. 일반적으로 예측하는 것보다 많은 수의 level을 주면 되며 많은 level을 설정한다고 해서 성능에 큰 영향은 없다. 총 레벨이 레벨 7을 넘어갈 것 같다고 판단되는 경우에만 설정해도 된다.

