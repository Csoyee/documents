# RocksDB Implementation
[참조 - Implementation Detail](https://github.com/facebook/rocksdb/wiki/)
> 위의 문서를 번역 (영어가 더 이해하기 쉬운 단어는 따로 번역 X)

---
## 1. Delete Stale Files   
[참조](https://github.com/facebook/rocksdb/wiki/Delete-Stale-Files)

더 이상 사용되지 않는 파일이 어떻게 제거되는가에 대한 내용이다.
### SST Files
- 컴팩션 끝나면 컴팩션의 인풋으로 사용된 SST 파일은 아웃풋 파일로 대체된다. 하지만 이들은 그 즉시 삭제되지 않는다. Old 버전의 LSM-tree 를 사용하고 있는 오퍼레이션이 있을 수 있기 때문에 해당 작업이 끝났음을 보장받을 때 까지 컴팩션의 인풋으로 사용된 파일을 삭제할 수 없다. 어떻게 LSM-tree 버저닝을 수행하는 가는 추후 설명할 예정이다. 
- 아래의 작업이 수행되고 있는 경우 old 버전의 LSM-tree 를 유지하고 있어야 한다.

1. Live iterator: Iterator 이 생성되는 동안 LSM 버전을 고정한다. 해당 버전의 모든 SST 파일은 삭제되지 않고 유지되어야 한다. 이는 iterator이 생성된 시점의 스냅샷을 유지하고 해당 스냅샷의 데이터를 읽어오기 때문이다.
2. Ongoing Compaction: 다른 컴팩션 작업이 해당 파일을 사용하고 있지 않더라도 컴팩션 시점의 모든 LSM-tree 버전은 유지되어야 한다.
3. Short window during Get(): Get() 명령이 수행되는 동안 LSM-tree 버전이 고정되어 해당 버전의 모든 immutable SST 파일을 읽을 수 있다. 만일 그 어떤 operation 도 *파일A*에 대한 LSM-Tree 버전을 유지하고 있지 않으면 *파일A* 은 삭제될 자격을 갖춘다.

- 위의 제약 사항에 걸리지 않고 삭제될 자격을 갖춘 파일들은 __두 가지 방법__ 에 의해서 삭제된다. 

---
#### 1) Reference counting
- 락스디비는 모든 SST 파일에 대한 reference count를 메모리에 가지고 있다. 각각의 LSM-tree 버전은 해당 버전의 모든 SST 파일에 대해서 reference count를 가지고 있다. 뿐만 아니라 위에서 설명한 작업들은 직/간접적으로 "super version"을 통해 특정 LSM-tree 버전에 대한 reference count 를 유지하는데 이 때 이 버전의 reference count가 0이 되면 해당 버전에 속하는 모든 SST 파일의 reference count 는 0이된다. SST file 의 reference count가 0이 되면 해당 파일은 지워질 수 있다. 일반적으로 이러한 파일들은 즉시 제거가 된다. 하지만 아래와 같은 예외 사항이 있을 수 있다.

1. 
2. Get() 혹은 몇몇 다른 작업들에서 특정 버전의 LSM-tree를 dereference 해서 SST 파일이 stale 해진 경우 해당 파일들은 지워지지 않고 저장된다. 다음 플러시 작업이 해당 파일들을 제거하거나 혹은 다른 쓰레드에 의해서 제거된 SSt 파일들과 함께 제거될 것이다. 이 방법을 통해 Get()을 수행할 때는 어떠한 파일 제거 I/O가 수행되지 않도록 하였다. 따라서 플러시가 일어나지 않으면 stale 파일들이 삭제되지 않고 남아있을 수 있음에 유의해야한다.
3. 만일 유저가 `DB::DisableFileDeletions()` 을 부르면 제거되려고 했던 모든 파일들은 제거되지 않고 유지된다. `DB::EnableFileDeletions()`를 통해 파일 제거에 대한 제약을 풀면 pending 됐던 모든 SST 파일들이 제거될 것이다.

#### 2) Listing all files to find stale files
- Reference counting 방법은 대부분의 경우 잘 동작하지만 persistent 하지 않다. 따라서 DB를 재시작하면 reference 정보를 잃게되기 때문에 또 다른 GC 매커니즘이 필요하다. 우리는 이와 같은 full GC 를 DB 재시작 시점에 수행하며 `options.background_purge_on_iterator_cleanup` 옵션에 기반하여 주기적으로도 수행한다. (후자가 더 안전)

- 다음과 같은 full GC 모드에서는, DB 디렉토리 내의 모든 파일들을 나열하고 각각의 파일에 대해서 live version의 LSM-tree 가 있는지, 파일이 사용되고 있는지를 확인한다. 필요하지 않응 파일은 제거한다. 하지만 live LSM-tree 버전에 속하지 않은 모든 SST 파일이 stale 하지는 않다. ongoing compaction 혹은 flush 를 통해서 생성되고 있는 파일들은 제거되어서는 안된다. 이를 방지하기 위해서 rocksdb는 새로 파일을 생성할 때 해당 파일에 대한 숫자를 오름차순으로 생성한다. flush/compaction 수행 전에 가장 마지막으로 생성된 SST 파일의 숫자를 기억하고 full GC 가 작업이 끝나기 전에 수행되면 해당 숫자보다 높은 값을 갖는 모든 파일들은 삭제되지 않는다. 여러개의 flush/compaction 작업이 병렬적으로 수행될 수 있기 때문에 가장 먼저 수행된 작업이 기억하고 있는 파일 숫자를 관리하고 있어야 한다. 

---
## 2. How we keep track of live SST files 
[참조](https://github.com/facebook/rocksdb/wiki/How-we-keep-track-of-live-SST-files)
- 락스디비의 LSM tree 는 SST 파일 리스트로 구성되어 있다. 각각의 컴팩션 과정 이후에 컴팩션 아웃풋 파일이 리스트에 추가되고 컴팩션 인풋 파일들은 해당 리스트에서 삭제된다. 하지만 리스트에서 제거된 인풋파일들이 리스트에서 제거되자마자 삭제되는 것은 아니다. 그 이유는 `get` 이나 `iterators` 작업이 끝날 때까지 혹은 iterator이 free 될 때까지 해당 파일을 필요로할 수 있기 때문이다. 그렇다면 이러한 정보는 어떻게 유지할까?

- LSM tree 에서 파일 리스트는 `version` 이라는 자료구조로 관리한다. Compaction 이나 memtable flush가 끝나면 갱신된 LSM tree에 대해서 새로운 `version` 이 생성된다. 물론 한 시점에 up-to-date LSM tree를 의미하는 "current" `version`은 오직 하나이다. 새로운 `get` 작업이나 `iterator`은 current version을 사용할 것이다. 

- `get` 혹은 `iterator`에서 사용되고 있는 모든 `version`들은 유지되어야하며 어떠한 용도로도 사용되고 있지 않은 out-of-date `version`은 drop되어야 한다. 이 과정에서 그 어떠한 `version`에 의해서도 사용되지 않는 파일들은 제거되어야 한다. 

__(예시)__  
3개의 파일을 가진 `version`을 초기에 가지고 있었다고 가정하자.
```bash
v1 = {f1, f2, f3}  (current)
files on disk: f1, f2, f3
```
그러던 중 iterator 이 생성되면 아래와 같이 된다.
```bash
v1 = {f1, f2, f3}  (current, used by iterator 1)
files on disk: f1, f2, f3
```
그러던 중 flush가 발생하여 `f4` 라는 파일이 생성되었다.
```bash
v2 = {f1, f2, f3, f4} (current)
v1 = {f1, f2, f3} (used by iterator 1)
files on disk: f1, f2, f3, f4
```
다음으로 컴팩션이 발생하여 `f2`, `f3`, `f4` 파일이 컴팩션되고 새로운 파일 `f5` 가 생성되었다.
```bash
v3 = {f1, f5} (current)
v2 = {f1, f2, f3, f4}
v1 = {f1, f2, f3} (used by iterator 1)
files on disk: f1, f2, f3, f4, f5
```
이제 `v2` 는 up-to-date 한 파일도 아니며 따로 사용되고 있는 파일도 아니다. 따라서 제거될 자격을 갖추게 되어 여전이 `iterator1`에 의해서 사용되고 있는 `v1`과 다르게 `v2`는 `f4` 파일과 함게 제거되게 된다. 
```bash
v3 = {f1, f5} (current)
v1 = {f1, f2, f3} (used by iterator 1)
files on disk = f1, f2, f3, f5
```
다음으로 `iterator 1`이 종료되면 `v1`도 파일 `f2`, `f3` 과 함께 제거된다.
```bash
v3 = {f1, f5} (current)
files on disk = f1, f5
```

- 이러한 방법은 reference count 를 기반으로 만들어졌다. SST 파일과 `version` 모두 reference count 를 갖는다. 새로운 `version`을 만들면 해당 `version`에 속하는 모든 SST file 들의 reference count 를 증가하며 `version`이 더이상 필요하지 않게되면 해당 `version`에 속한 모든 파일의 reference count가 1 감소한다. 이러던 중 파일에 대한 reference count가 0이 되면 해당 파일은 제거될 수 있다. 

- 이와 비슷하게 `version` 역시 reference count 를 가지고 있다. `version` 이 생성되면 up-to-date 하기 때문에 해당 `version`의 reference count 가는 1이다. 만일 `version`이 up-to-date 이 아니게 되면 reference count는 1 감소한다. 해당 `version`을 사용하는 누군가가 있을 때 `version`의  reference count 가 증가하며 사용이 끝나 아무도 사용하지 않고 up-to-date 하지 않으면 해당 `version`은 제거될 수 있다. 

- 종종 reader 은 `version` 에 대한 reference 를 직접 잡고 있을 때도 있지만 대부분의 경우 reader 은 `super version` 이라는 간접적인 자료 구조를 사용한다. 후자의 경우 실제 `version`에 대한 reference 를 잡고 있는 것은 `super version` 이며 해당 방법은 locking 등을 피하는 등의 최적화 기회를 갖고 있다. 

- RocksDB 는 `version` 에 대한 자료구조를 `VersionSet` 이라는 구조체로 관리하고 있으며 어떤 `version` 이 최신의 버전인지 기억하고 있다. 이 때, 각각의 `column family`는 별개의 LSM 이기 때문에 `column family` 별로 `version` list 를 관리한다. 하지만 `VersionSet` 은 DB 당 하나이다. 

---
## 3. Iterator Implementation
[참조](https://github.com/facebook/rocksdb/wiki/Iterator-Implementation)

### RocksDB Iterator 
- RocksDB Iterator 은 유저가 DB를 정렬된 형태로 앞/뒤로 iterate 할 수 있도록 한다. 또한 특정한 key 를 DB 안에서 찾을 수 있도록 한다. 이를 위해서 iterator 은 DB를 정렬된 스트림으로서 접근할 수 있다. RocksDB iterator 은 `DBIter` 이라는 이름으로 구현되었다. 

#### DBIter
> Interface: Iterator
- `DBIter`은 `InternalIterator`(`Merging Iterator`)의 wrapper `Internal Iterator` 내부의 키를 파싱해서 유저키로 보여주는 역할을 한다. 

__Example__
아래의 `InternalIterator`는 다음과 같이 구성되어 있다.
```bash
InternalKey(user_key="Key1", seqno=10, Type=Put) | Value="KEY1_VAL2"
InternalKey(user_key="Key1", seqno=9 , Type=Put) | Value="KEY1_VAL1"
InternalKey(user_key="Key2", seqno=16, Type=Put) | Value="KEY2_VAL2"
InternalKey(user_key="Key2", seqno=15, Type=Delete) | Value="KEY2_VAL1"
InternalKey(user_key="Key3", seqno=7 , Type=Delete) | Value="KEY3_VAL1"
InternalKey(user_key="Key4", seqno=5 , Type=Put) | Value="KEY4_VAL1"
```
하지만 `DBIter` 이 유저에게 보여주는 것은 아래와 같다. 
```bash
Key="Key1" | Value = "KEY1_VAL2"
Key="Key2" | Value = "KEY2_VAL2"
Key="Key4" | Value = "KEY4_VAL1"
```

#### Merging Iterator
> Interface: InternalIterator 
- `MergingIterator`은 많은 child iterator 들로 구성되어 있다. `MergingIterator` 은 기본적으로 Iterator들의 heap 이다. `MergingIterator` 안 heap에 모든 child iterator 들을 넣고 하나의 소팅된 스트림처럼 보여준다.

__Example__
Child Iterator 는 아래와 같다.
```bash
= Child Iterator 1 =
InternalKey(user_key="Key1", seqno=10, Type=Put) | Value="KEY1_VAL2"

= Child Iterator 2 =
InternalKey(user_key="Key1", seqno=9 , Type=Put) | Value="KEY1_VAL1"
InternalKey(user_key="Key2", seqno=15, Type=Delete) | Value="KEY2_VAL1"
InternalKey(user_key="Key4", seqno=5 , Type=Put) | Value="KEY4_VAL1"

= Child Iterator 3 =
InternalKey(user_key="Key2", seqno=16, Type=Put) | Value="KEY2_VAL2"
InternalKey(user_key="Key3", seqno=7 , Type=Delete) | Value="KEY3_VAL1"
```
`MergingIterator` 은 child Iterators 들을 heap 에 저장하고 하나의 소팅된 스트림으로 보여준다.
```bash
InternalKey(user_key="Key1", seqno=10, Type=Put) | Value="KEY1_VAL2"
InternalKey(user_key="Key1", seqno=9,  Type=Put)    | Value = "KEY1_VAL1"
InternalKey(user_key="Key2", seqno=16, Type=Put)    | Value = "KEY2_VAL2"
InternalKey(user_key="Key2", seqno=15, Type=Delete) | Value = "KEY2_VAL1"
InternalKey(user_key="Key3", seqno=7,  Type=Delete) | Value = "KEY3_VAL1"
InternalKey(user_key="Key4", seqno=5,  Type=Put)    | Value = "KEY4_VAL1"
```

#### MemtableIterator
> Interface: InternalIterator
- `MemtableRep::Iterator`의 래퍼로 모든 memtable 은 memtable 안에 있는 key/value 들을 정렬된 스트림으로 보여주기 위해서 자신만의 iterator 을 가진다. 

#### BlockIter
> Interface: InternalItertor
- 이 iterator 은 SST 파일에서 block이 인덱스 블록이든 데이터 블록이든 상관없이 block 을 읽기 위해서 사용된다. SST 파일블록은 정렬되어 있고 바뀌지 않기 때문에 우리는 block 을 메모리에 로드해서 `BlockIter` 을 만들 수 있다.

#### TwoLevelIterator
> Interface: InternalIterator
- `TwoLevelIterator`은 두개의 Iterator 로 구성된다: `first_level_iter_`(for index block)/`second_level_iter`(for data block);
- `first_level_iter_` 은 `second_level_iter_`을 찾아내기 위해서 사용되며, `second_level_iter_`은 실제 읽는 데이터를 가리킨다. 


## 4. Merge Operator

### Why
- RocksDB는 3가지 간단한 오퍼레이션 Get, Put, Delete 를 제공한다. 종종 현존하는 데이터를 업데이트하는 경우가 생기게 되는데 락스디비에서 이를 수행하기 위해서는 해당 데이터를 읽어낸 후 (Get), 수정하고 다시 쓰는 (Put) 과정이 필요하다. 

- High level opertaion인 Set, Add, Get, Remove 를 구현한다고 가정했을 때 Add 를 제외한 다른 operation 들은 락스디비에서 제공하는 operation과 바로 매칭되지만 (Set-Put, Get-Get, Remove-delete) Add (Get and Set) 는 그렇지 않다. 이는 성능 문제 등을 내포하고 있다 (락스 디비의 랜덤 read 성능은 좋지 못함).

- 위의 operation을 서비스로 제공한다고 가정했을 때 최근 서버에는 많은 코어들이 사용됨을 고려하면 해당 서비스를 대부분 멀티스레드로 사용할 것이다. 만일 쓰레드가 key space 에 따라서 파티션되어있지 않으면 서로 다른 쓰레드가 동일한 데이터에 대해서 Add 요청을 여러번 보내서 동시에 수행될 수 있다. 만일 우리가 엄격한 consistency를 가지고 있다면 동기화를 통해서 락을 잡는 과정에서 오버헤드가 증가할 것이다. 

- 이에 아래와 같이 RocksDb 가 직접적으로 Add 기능을 제공하면 어떨까? 
```bash
virtual void Add(const string& key, uint64_t value) {
  string serialized = Serialize(value);
  db->Add(add_option, key, serialized);
}
```
- 위의 operation은 Counter을 구현할 때에는 합리적일 수 있으나 다른 경우가 있을 수 있다. 예를 들어, 유저가 사용했던 위치를 추적해야하는 경우 현존하는 리스트에 새로운 위치를 추가하는 것이 일반적일 것이다. 이 경우 Append operation: `db->Append(user_key, serialize(new_location))` 이 필요하다. 즉, 이와 같이 어떤 client value 타입에 대한 요청인가에 따라 read-modify-write 작업의 시멘틱이 달라질 수 있다. 라이브러리를 일반화하여 사용하기 위해서는 operation 을 더 추상화하고 클라이언트가 semantic을 특정할 수 있도록 허용해야 한다. 이러한 요구 사항으로 `Merge` operation 을 제안하게 되었다. 

