# MyRocks Document


Reference:
- [Percona, MyRocks Introduction](https://www.percona.com/live/17/sites/default/files/slides/MyRocks_Tutorial.pdf)
- [Percona, Things to Know Before You Start](https://www.percona.com/blog/2018/02/01/myrocks-engine-things-know-start/)



## Introduction

### B+Tree (InnoDB)
- B+Tree 의 인덱스 리프 페이지 사이즈는 InnoDB 에서는 디폴트 16KB 로 작은편에 속한다. 더불어 random order 로 수정이 이뤄지기 때문에 Random Writes/REads 가 발생하게 되는데 이는 최악의 경우 N 번의 row 수정에 대해서 N 번의 page write 를 수행한다. 

- **Write Amplification on B+Tree:** 1 Byte 의 변화만으로 1 page write 가 유발될 수 있으며, data consistency 를 위해서 double write buffer 을 사용하는 경우에는 write 의 양이 2 배로 증가한다.

- **Btree Fragmentation increases Space:** B+tree 는 기본적으로 leaf page 가 일정 threshold 이상 차게 되면 split 되어 두 개의 page 로 나눠지게 된다. 이 경우 split 된 페이지들은 page 에 꽉차게 데이터를 보유하고 있는 것이 아니라 empty space 를 가지며 이는 SAF (Space Amplification Factor) 을 증가시키는 원인이 된다.



### LSM Tree (RocksDB)

- RocksDB 는 Leveled LSM (Log Structured Merge) 구조를 가진다. LSM 는 random row 업데이트가 발생하더라도 Compaction 과정을 통해서 sequential read/write 를 유발한다. 

- Lower write Amplification

- 하지만 LSM 구조에서는 Read Penalty 를 가진다. InnoDB 의 B+Tree 에서는 Range Scan 을 할 때에 leaf pages 를 순차적으로 읽어내면 되지만 LSM Tree 에서는 어떤 레벨에 있는지 알 수 없기 때문에 상위 레벨부터 모든 레벨을 확인해야하기 때문에 더 많은 CPU cycle 을 요한다. (빠른 read 를 위한 Bloom filter 와 같은 기능이 있다.)

- Column Family: 별도의 Memtable 과 SST files 들을 가지고 잇으나 transactional logs (WAF) 은 공유한다.

- Delete panalty: Delete 의 경우 어느 레벨까지 동일 key data 가 존재하는지 모르기 때문에 맨 아래 레벨의 compaction 을 수행할 때까지 지워지지 않는다. (--> SingleDelete Optimization : 만일 동일 key 에 대한 Put 이 한번만 일어났음이 보장이 되면 아래 레벨까지 내려가지 않고 Put 과 Delete 가 같이 없어진다.)


## MyRocks Features

### MyRocks Data Structure and Schema Design

- Primary Key, Secondary Key 를 지원한다. 

- Primary Key 는 InnoDB 와 비슷하게 clustered 되어 single step 으로 수행될 수 있다.

- Fulltext, Foreign, Spatial Index 는 지원되지 않는다.

- **Interface Index ID:** MyRocks 는 각각의 index 에 대해서 4 byte 의 인덱스 아이디를 부여한다. 해당 아이디는 모든 MyRocks 의 내부 operation (read/write/update/delete rows) 에 사용된다. 

### Column Family 

- **Index and Column Family:** Column Family 와 MyRocks의 Index 는 1:N mapping 관계를 갖는다. 즉 여러 인덱스들이 동일 Column Family 에 존재할 수 있다. 하지만 다른 종류의 인덱스는 다른 Column Familty 에 존재할수도 있다. 

- 아래와 같이 INDEX COMMENT 를 통해서 연관된 column familty 를 지정할 수 있으며 만일 해당 column family 가 이미 존재하지 않는다면 RocksDB 에서 자동으로 생성한다. 

```bash
CREATE TABLE `linktable` (
`id1` bigint unsigned,
`id1_type` int unsigned,
`id2` bigint unsigned,
`id2_type` int unsigned,
`link_type` bigint unsigned,
`visibility` tinyint NOT NULL,
`data` varchar NOT NULL,
`time` bigint unsigned NOT NULL,
`version` int unsigned NOT NULL,
PRIMARY KEY (link_type, `id1`,`id2`) COMMENT 'cf_link_pk',
KEY `id1_type` (`id1`,`link_type`,`visibility`,`time`,`version`,`data`) COMMENT 'rev:cf_link_id1_type'
) ENGINE=RocksDB DEFAULT COLLATE=latin1_bin;
```
### Faster Data Loading / Deletes / Replication

- **Faster Data Loading:** MemTable writes, compaction 하지 않고 바로 아래 레벨부터 채워나감.

- **Faster Replication:** Read Free Replication - Random Read 를 피하기 위해서 constraint check 조건을 다음과 같이 완화한다.:  Insert 시에 uniq constraint check 를 하지 않음. Update/Delete 시에 row 확인하지 않음; 이는 LSM 과 같은 Appned Only Database 이기 때문에 가능하다. 

### DirectIO

- MyRocks 는 완전한 Direct IO 를 지원하지 않는다. (?? 테스트 필요)

### Graceful SST File Deletes on Flash

- Compaction 시에 여러 파일들이 Compaction 의 대상이 되기 때문에 여러 delete 대상이 발생하게 된다. 이 때 여러 파일을 한번에 삭제하고 그간에 interval 을 제공하지 않으면 Flash 에서 TRIM stall 과 같은 문제가 발생할 수 있다.

- `rocksdb-sst-mgr-rate-bytes-per-sec` 를 통해서 삭제 속도를 통제할 수 있다.



### + Differences

- 벌크 로드를 하는 경우에, 많은 양의 데이터를 MyRocks에 한번에 로드하고자 하는 경우 충분한 메모리가 없어 RocksDB 가 crash 될 수 있다. 따라서 이런 경우 `rocksdb_bulk_load=1`을 설정하며 MemTable 이나 compaction 을 건너 뛰고 모든 insert data 를 RocksDB 의 하위 레벨부터 넣도록 한다. 

- MyRocks 의 블록캐시는 'innodb_buffer_pool_size' 와 비슷하지만 MyRocks 에서는 주로 read 를 하는데 이점을 가진다. 

- LSM tree 는 기본적으로 level 이 꽉차면 merge (compaction) 과정을 수행하여 compacted data 를 다음 레벨로 옮긴다. 이 과정은 유저 쿼리에 영형을 줄 수 있으며 영향성을 줄이기 위해서 튜닝을 수행할 수 있다.


이외에 MyRocks 가 가지는 여러가지 [한계점](https://www.percona.com/doc/percona-server/LATEST/myrocks/limitations.html)들이 있다. 

