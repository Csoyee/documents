# btt 


[blktrace](https://linux.die.net/man/8/blktrace) 를 통해서 출력한 block i/o trace 를 분석하는 툴로 자세한 내용은 [man page](https://linux.die.net/man/1/btt) 참조.


btt 를 활용하여 block trace 의 action level로 I/O 가 소요한 시간에 대한 분석을 제공하며 뿐만 아니라 각 영역간 이동에 소요된 시간을 분류한다.

```markdown
Q --> G -------------> I --> M ------------------> D --------------------------------> C
|-Q-|--insert time --|                                 
|--------Merge Time----------|-Merge with other IO-|
|-----------Scheduler Time-------------------------|-- driver, adaptor, storage time --|
|-------Block Layer Time---------------------------------------------------------------|
```

위의 시간을 세부적으로 보면 다음과 같다:
- Q2Q: request 가 block layer 로 보내질 때까지의 시간
- Q2G: block I/O 가 queueing 된 후 request 를 할당받을 때까지의 시간
- G2I: request 가 할당된 후에 device queue 로 삽입될 때까지의 시간
- Q2M: block I/O 가 queuing 된 후 부터 이미 존재하는 request 와 merge 될 때까지의 시간
- I2D: request 가 device queue 에 삽입된 후 부터 실제 디바이스로 이슈될 때까지의 시간
- D2C: device 에 의해서 request 가 처리되는 시간
- Q2C: 전체 block layer에서 소요된 시간. 

인풋 파일 btrace.txt 에 대해서 위의 시간 결과를 얻기 위해서 다음 명령을 사욯하면 된다.
```bash
$ btt -i btrace.txt
```


다른 옵션 (e.g., -l) 을 사용하여 각 레벨에서의 latency 등을 출력할 수도 있다. 
