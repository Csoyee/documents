# Simple Discard Test 



다음 실험 결과는 4K 단위로 `discard`  명령을 내리고 다 내린 후에 `fsync()` call 을 한 결과이다. 


## Observation1: Make Sample File in Random vs. Sequential Manner

- 샘플 파일을 제작할 때에 순차 쓰기를 하는 경우와 랜덤 쓰기를 하는 경우를 비교함

### Total 4M Discard

|      Sequential Load      |        Random Load        |
|:-------------------------:|:-------------------------:|
| 0.010s (IO time: 0.003 s) | 0.011s (IO time: 0.003 s) |

### Total 64M Discard

|      Sequential Load      |        Random Load        |
|:-------------------------:|:-------------------------:|
| 0.057s (IO time: 0.005 s) | 0.064s (IO time: 0.010 s) |

- 64M Discard 를 한 경우를 보면 IO time 이 2배 정도 차이나기는 하나 4M Discard 했을 경우에는 거의 차이가 나지 않음.



## Observation2: Issue Discard into Sequential Offset vs. Discrete Offset

- 4K 단위 discard 를 내릴 때 연속된 offset (e.g., 0, 1, 2, 3 ...) 영역에 내리는 경우와 불연속된 offset (e.g., 0, 4, 8, 12 ...) 영역에 내리는 경우를 비교함

### Total 4M Discard

|     Sequential Region     |      Discrete Region      |
|:-------------------------:|:-------------------------:|
| 0.015s (IO time: 0.004 s) | 0.175s (IO time: 0.166 s) |

### Total 64M Discard

|     Sequential Region     |     Discrete Region     |
|:-------------------------:|:-----------------------:|
| 0.067s (IO time: 0.005 s) | 2.695s (IO time: 2.628) |


- discrete region 에 내리는 경우에 훨씬 수행 시간 (특히 IO time) 이 많이 증가함. 
- blktrace 를 확인해보면 Sequential Region 에 discard 를 하는 경우에는 Total Discard Amount 만큼의 request 가 한번에 내려오는 반면 Discrete Case 에는 4K 단위로 쪼개져서 내려온다.


## Observation3: fsync every time you discard, and fsync after all.

- 본 실험에서는 연속된 offset 영역에 대해서 discard 를 수행했다,

### Total 4M Discard

| Fsync after all | Fsync Every Time |
|:---------------:|:----------------:|
| 0.015           | 2.920            |



### Total 64M Discard

| Fsync after all | Fsync Every Time |
|:---------------:|:----------------:|
| 0.067           | 46.326           |

- Discard call 을 쪼개어서 보내는 것 자체가 오버헤드 + 각각의 discard 의 처리를 기다리는 overhead
