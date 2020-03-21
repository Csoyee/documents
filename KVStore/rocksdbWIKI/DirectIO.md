# Direct IO 

## Implementation

1. File Open
  Linux의 경우 파일 오픈 시점에 `O_DIRECT` flag 를 준다. 
2. File R/W
  Direct I/O 를 수행할 때 file R/W가 *logical sector size* 에  aligned 되어야 한다. 모든 alignment logic 은 file classes 보다 한 단계 상위 레이어에 있는 `File Reader/Fie Writer` 에 구현되어 있다.
 
 
## Notes
1. `use_direct_io_for_flush_and_compaction`, `use_direct_reads` 옵션을 켜더라도 이는 SST 파일을 쓸 때에만 적용되고 WAL이나 MANIFEST 파일에는 적용되지 않는다. (아직 WAL 및 Manifest 파일에 대한 direct option 은 존재하지 않음.)

2. direct I/O 를 켜면 compaction wirtes 가 더이상 OS page cache 에 올라가지 않기 때문에 처음 read 할 때는 disk IO 가 발생할 것이다. Page cache를 대신해서 compressed block cache feature을 사용할 사용할 수 있으나 아래의 몇 가지 이슈들이 있다.
  - fragmentation: compressed block은 page size 에 aligned 되지 않는다. Compressed block 은 malloc 으로 할당된 memory 영역에 위치하게 될 텐데 이는 memory fragmentation을 유발함을 의미한다. 
  - OS page cache는 read ahead 를 제공한다. Default configuration으로는 꺼져있지만 read ahead 모드를 켤 수 있다. 이는 range-loop 워크로드에 좋지만 compressed cache 는 이러한 장점을 사용할 수 없다.
  - 버그가 생할 가능성이 있다. 내부적으로 사용되지 않고 있으며 외부의 유저에 의한 버그 레포트들이 있으나 제대로 처리되지 않고 있다.
  
3. 락스디비 위키페이지에는 `use_direc_io_for_flush_and_compaction` 을 할 경우 read, write 모두 direct mode 로 수행된다고 명시되어 있으나 5.16 버전 코드를 보았을 때 write 만 direct mode 로 동작함을 확인하였다.
