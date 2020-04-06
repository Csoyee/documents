# cachestat

Linux ftrace 를 활용해서 linux page cache 의 hit/miss 통계치를 보여주는 툴.

> COPYRIGHT: Copyright (c) 2014 Brendan Gregg.


## 작동 원리 

- Linux 에서 cache 에 접근했을 때 `mark_page_accessed()` 함수가 불리며 cache 에 write 를 하면 `mark_buffer_dirty()` 라는 함수가 불린다. 
- 또한 `add_tioo_page_cache_lru()` 함수는 page 가 추가되었음을 `account_page_dirtied()` 는 dirty page 를 측정하기 위해서 사용된다. 이를 ftrace 를 통해 분석해 page cache 에 대한 통계치를 리턴한다. 

## 사용 방법

### Setting

```bash
# cachestat 실행 파일 다운로드
$ wget https://raw.githubusercontent.com/brendangregg/perf-tools/master/fs/cachestat

# 권한 변경
$ sudo chmod u+x cachestat
```

### Run
```bash
# 실행
$ sudo ./cachestat
```

### Result
- cachestat을 수행하면 1초마다 cache 접근 정보를 출력해준다. 아래는 출력 예시이다. 
- 현재 간단한 monitoring 프로그램만 수행 중이어서 cache 가 차지 않은 상태로 계속 cache hit 이 발생한다.

```bash
Counting cache functions... Output every 1 seconds.
    HITS   MISSES  DIRTIES    RATIO   BUFFERS_MB   CACHE_MB
    2937        0        0   100.0%          309      36129
    2938        0        0   100.0%          309      36129
    2968        0        0   100.0%          309      36129
Ending tracing...
```
