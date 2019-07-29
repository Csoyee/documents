# RocksDB Implementation
[참조 - Implementation Detail](https://github.com/facebook/rocksdb/wiki/)
> 위의 문서를 번역 (영어가 더 이해하기 쉬운 단어는 따로 번역 X)

## 1. Delete Stale Files   
[참조](https://github.com/facebook/rocksdb/wiki/Delete-Stale-Files)

더 이상 사용되지 않는 파일이 어떻게 제거되는가에 대한 내용이다.
### SST Files
 컴팩션 끝나면 컴팩션의 인풋으로 사용된 SST 파일은 아웃풋 파일로 대체된다. 하지만 이들은 그 즉시 삭제되지 않는다. Old 버전의 LSM-tree 를 사용하고 있는 오퍼레이션이 있을 수 있기 때문에 해당 작업이 끝났음을 보장받을 때 까지 컴팩션의 인풋으로 사용된 파일을 삭제할 수 없다. 어떻게 LSM-tree 버저닝을 수행하는 가는 추후 설명할 예정이다. 
아래의 작업이 수행되고 있는 경우 old 버전의 LSM-tree 를 유지하고 있어야 한다.

1. Live iterator: Iterator 이 생성되는 동안 LSM 버전을 고정한다. 해당 버전의 모든 SST 파일은 삭제되지 않고 유지되어야 한다. 이는 iterator이 생성된 시점의 스냅샷을 유지하고 해당 스냅샷의 데이터를 읽어오기 때문이다.
2. Ongoing Compaction: 다른 컴팩션 작업이 해당 파일을 사용하고 있지 않더라도 컴팩션 시점의 모든 LSM-tree 버전은 유지되어야 한다.
3. Short window during Get(): Get() 명령이 수행되는 동안 LSM-tree 버전이 고정되어 해당 버전의 모든 immutable SST 파일을 읽을 수 있다. 만일 그 어떤 operation 도 *파일A*에 대한 LSM-Tree 버전을 유지하고 있지 않으면 *파일A* 은 삭제될 자격을 갖춘다.

위의 제약 사항에 걸리지 않고 삭제될 자격을 갖춘 파일들은 두 가지 매카니즘에 의해서 삭제된다. 

### Reference counting
 락스디비는 모든 SST 파일에 대한 reference count를 메모리에 가지고 있다. 각각의 LSM-tree 버전은 해당 버전의 모든 SST 파일에 대해서 reference count를 가지고 있다. 뿐만 아니라 위에서 설명한 작업들은 직/간접적으로 "super version"을 통해 특정 LSM-tree 버전에 대한 reference count 를 유지하는데 이 때 이 버전의 reference count가 0이 되면 해당 버전에 속하는 모든 SST 파일의 reference count 는 0이된다. SST file 의 reference count가 0이 되면 해당 파일은 지워질 수 있다. 일반적으로 이러한 파일들은 즉시 제거가 된다. 하지만 아래와 같은 예외 사항이 있을 수 있다.
 
1. 
2. Get() 혹은 몇몇 다른 작업들에서 특정 버전의 LSM-tree를 dereference 해서 SST 파일이 stale 해진 경우 해당 파일들은 지워지지 않고 저장된다. 다음 플러시 작업이 해당 파일들을 제거하거나 혹은 다른 쓰레드에 의해서 제거된 SSt 파일들과 함께 제거될 것이다. 이 방법을 통해 Get()을 수행할 때는 어떠한 파일 제거 I/O가 수행되지 않도록 하였다. 따라서 플러시가 일어나지 않으면 stale 파일들이 삭제되지 않고 남아있을 수 있음에 유의해야한다.
3. 만일 유저가 `DB::DisableFileDeletions()` 을 부르면 제거되려고 했던 모든 파일들은 제거되지 않고 유지된다. `DB::EnableFileDeletions()`를 통해 파일 제거에 대한 제약을 풀면 pending 됐던 모든 SST 파일들이 제거될 것이다.

### Listing all files to find stale files
Reference counting 방법은 대부분의 경우 잘 동작하지만 persistent 하지 않다. 따라서 DB를 재시작하면 reference 정보를 잃게되기 때문에 또 다른 GC 매커니즘이 필요하다. 우리는 이와 같은 full GC 를 DB 재시작 시점에 수행하며 `options.background_purge_on_iterator_cleanup` 옵션에 기반하여 주기적으로도 수행한다. (후자가 더 안전)

다음과 같은 full GC 모드에서는, DB 디렉토리 내의 모든 파일들을 나열하고 각각의 파일에 대해서 live version의 LSM-tree 가 있는지, 파일이 사용되고 있는지를 확인한다. 필요하지 않응 파일은 제거한다. 하지만 live LSM-tree 버전에 속하지 않은 모든 SST 파일이 stale 하지는 않다. ongoing compaction 혹은 flush 를 통해서 생성되고 있는 파일들은 제거되어서는 안된다. 이를 방지하기 위해서 rocksdb는 새로 파일을 생성할 때 해당 파일에 대한 숫자를 오름차순으로 생성한다. flush/compaction 수행 전에 가장 마지막으로 생성된 SST 파일의 숫자를 기억하고 full GC 가 작업이 끝나기 전에 수행되면 해당 숫자보다 높은 값을 갖는 모든 파일들은 삭제되지 않는다. 여러개의 flush/compaction 작업이 병렬적으로 수행될 수 있기 때문에 가장 먼저 수행된 작업이 기억하고 있는 파일 숫자를 관리하고 있어야 한다. 

