# YCSB Workload

[Reference1](https://github.com/brianfrankcooper/YCSB/wiki/Core-Workloads) : workload 구성  
[Referemce2](https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties) : 주요 property

## Workload 의 구성
- A: 50 read / 50 update _ update heavy workload
- B: 95 read / 5 update _ read mostly workload 
- C: 100 read _ read only
- D: 95 read / 5 insert _ read latest workload
- E: 95 scan / 5 insert _ short range
- F: 50 read / 50 RMW _ read-modify-write


## Running the workloads
- 데이터베이스 사이즈를 유지하면서 테스트하기 위해서는...

- Load the database using workload A's parameter file
- Run workload A
- Run workload B
- Run workload C
- Run workload F
- Run workload D (this workload inserts records)
- Delete the data in the database
- Reload the database using worklod E's parameter file
- Run workload E (this workload inserts records)

## Core properties 
- [read/update/insert/scan/readmodifywrite]proportion: (default: [0.95, 0.05, 0, 0, 0])
- requestdistribution: [uniform(default)/zipfian/latest] 
- operationcount: 수행할 오퍼레이션의 개수로 만일 0이면 maxexecution time 만큼의 시간 동안 수행을 한다. (default: 0)
- maxexecutiontime: 최대 수행 시간으로 초 단위로 조정할 수 있따. (default: infinitely run)
- fieldlength: field 의 사이즈
- fieldcount: field 의 개수  `value 사이즈는 fieldlength * fieldcount 로 default 는 100B * 10 = 1KB 이다.`
