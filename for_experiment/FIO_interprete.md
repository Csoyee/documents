# FIO 해석하기

헷갈리지 않게 정리정리 :-)  [reference](https://tobert.github.io/post/2014-04-17-fio-output-explained.html)


### 섹션 별 아웃풋 설명


#### io summarize
```bash
  read : io=10240MB, bw=63317KB/s, iops=15829, runt=165607msec
```
 첫 줄은 아주 쉽게 이해할 수 있다! FIO 가 총 10G 의 IO를 수행하는 동안 63.317MB/s, 15829 IOPS 를 보였음을 의미한다. 해당 io 의 수행시간은 2분 45초 정도이다.

#### latency
다음으로 latency 와 관련된 결과를 확인할 수 있다. latency 관련 결과 중 처음으로 확인할 수 있는 것은 `slat` 으로 이는 submission latency 를 의미한다. 
Submission latency 는 말그대로 "커널이 submit 된 IO 를 수행할 때까지 얼마만큼의 시간이 걸렸는지"를 의미한다.

```bash
    slat (usec): min=3, max=335, avg= 9.73, stdev= 5.76
```

다음으로 볼 것은 `clat`, completion latency 이다. 이는 커널로 submission 된 후부터 IO complete 까지의 시간을 의미한다. 아주 예전의 fio 버전에서는 `slat` 과 `clat` 이 latency-level latency 측정을 하기 위한 가장 좋은 기준이었다.
```bash
    clat (usec): min=1, max=18600, avg=51.29, stdev=16.79
```

하지만 이제는 `lat` 결과도 확인할 수 있다. lat 는 IO sturuct 가 만들어진 시점부터 `clat` 가 끝난 직후 까지의 시간으로 application level 에서 경험할 수 있는 latency 를 바로 확인할 수 있따.


Latency distribution section 은 usec, msec 단위로 latency 가 어떻게 분포하는지 확인할 수 있다.
```bash
    lat (usec) :   2= 0.01%,   4=0.01%,  10=0.01%,   20=0.01%, 50=51.41%
    lat (usec) : 100=48.53%, 250=0.06%, 500=0.01%, 1000=0.01%
    lat (msec) :   2= 0.01%,   4=0.01%,  10=0.01%,   20=0.01%
```
위의 경우를 예로 들면 51.41% 의 IO 가 20~50 usec 의 latency 를 보이고 48.53% 의 IO 50~100 usec 의 latency 를 보였음을 확인할 수 있다.

#### cpu
FIO 는 또한 cpu 사용률도 보여준다. 
```bash
  cpu          : usr=5.32%, sys=21.95%, ctx=2829095, majf=0, minf=21
```
위를 참고하면 user/system CPU 사용률을 확인할 수 있으며 context switch 와 major/minor page fault 도 확인할 수 있다. 


#### io depth 
```bash
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, &gt;=64=0.0%
```

FIO 는 IO depth 를 조정할 수 있다. iodepth 는 fio 가 내부적으로 큐잉할 I/O 의 최대 개수를 의미한다. 이는 application-side factor 로 device IO queue 와는 직접적인 관련이 없다. iodepth 가 1로 설정되면 IO depths 결과는 1에서 100% 로 나오게 된다.

> 만일 IO depth 를 늘렸을 때 iodepth 크기보다 낮은 숫자에서 100% 를 확인할 수 있다면 device 가 충분히 빠름을 의미한다.

```bash
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, &gt;=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, &gt;=64=0.0%
```
submit 과 complete 는 특정 순간에 submit 된 혹은 complet 된 iO 의 개수를 의미한다. 위의 예시에서는 iodepth 가 1로 설정되었기 때문에 1일때 100% 의 비율을 보인다.
즉, 해당 결과는 iodepth 가 1보다 클 때 의미있는 결과이다. 

또한 해당 결과는 어떤 스케쥴러를 사용했는지에 따라서 달라질 수 있다.


