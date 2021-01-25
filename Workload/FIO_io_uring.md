# FIO IO Uring Support

[FIO source code](https://github.com/axboe/fio)
Fio 3.13 version 부터 io_uring engine 을 지원.

> - FIO version 변경 (나는 3.16.7)  
> - io_uring 은 커널버전 5.1 이후부터 지원되므로 io_uring test를 위해서는 kernel 버전도 5.1 버전 이후로 맞춰주어야 한다. (나는 5.3)  


## How to use io uring
```bash
$> fio [--other options] --io_engine=io_uring 
```

제대로 동작하는지 확인, 나의 경우 [ftrace](https://github.com/Csoyee/documents/blob/master/tool/ftrace.md) 를 통해서 io_uring call 이 불리는지 확인하였다. 
아래와 같이 `__x64_sys_io_uring_enter`, `io_ring_submit`, `io_get_sqring.isra.21()` 등의 io_uring 관련 시스템 함수가 불린다.

![image](https://user-images.githubusercontent.com/18457707/66024940-2f85ce80-e530-11e9-8c7c-9a2a5686d75b.png)

## IO_URING engine specific options 

IO_URING 은 응용 프로그램에서 최적화 된 IO 인터페이스를 사용할 수 있도록 몇 가지 feature들을 제공하고 있다. fio 에서는 이러한 feature들을 설정할 수 있는 옵션을 제공한다.

### Fixed Files and Bufferes 

IO_URING interface를 활용하면 file io에 대해서 매번 file descriptor이 SQE에 기록되고 커널에 전달된다. 커널에서는 file descriptor이 지정한 파일과 관련된 데이터들을 찾아내야하고 IO가 완료되면 이러한 데이터들은 다시 drop 된다. File reference은 원자성(atomicity)을 가지기 떄문에 high IOPS 워크로드의 성능을 저해하는 결과를 초래할 수 있다. 이러한 문제를 완화하기 위해서 io_uring에서는 io_uring instance에 대한 파일 셋을 미리 등록(pre-register)하는 방법을 제공한다. `IORING_REGISTER_FILES` operation을 통해서 등록된 파일들에 파일 셋에 대해서는 응용에서는 실제 file descriptor이 아닌 array에 있는 index를 사용할 수 있다. (물론 등록된 파일 정보들은 io_uring instance가 종료되면 같이 free된다). FIO에서는 `registerfiles` 옵션을 통해서 이러한 기능을 활용할 수 있으며, 대부분 technical report에서 io_uring 실험을 진행할 때에 해당 옵션을 켠다. 아래는 [fio man page](https://fio.readthedocs.io/en/latest/fio_doc.html#cmdoption-arg-registerfiles)에서 해당 옵션에 대한 설명의 일부를 발췌한 것이다.

- `registerfiles`: This avoids the overhead of managing file counts in the kernel, making the submission and completion part more lightweight. 


IO_URING에서는 또한 고정된 IO buffer을 사용할 수 있도록 한다. Direct IO를 할 때에 kernel 이 application page를 커널에 매핑(io submit)/해제(io complete)하는 과정으로 인한 비용을 줄이기 위한 옵션이다. 본 옵션을 사용한 경우에는 IO 를 수행하기 전에 미리 page를 매핑해둔다. 아래의 설명은 [fio man page](https://fio.readthedocs.io/en/latest/fio_doc.html#cmdoption-arg-fixedbufs) 에서 발췌한 내용이다.

- `fixedbufs`: If fio is asked to do direct IO, then Linux will map pages for each IO call, and release them when IO is done. If this option is set, the pages are pre-mapped before IO is started. This eliminates the need to map and release for each IO. This is more efficient, and reduces the IO latency as well.

### POLLED IO

기존의 non-polled IO (relying on hardware interrupts)는 IO를 수행한 후에 sleep 상태가 되어 hardware interrupt가 꺠워주기를 기다린다. 이 때 Context switch overhead로 인해서 low latency storage를 사용할 때에는 이러한 interrupt 방식의 IO가 아닌 IO가 종료될 때까지 그냥 대기하는 polled IO 를 사용하기도 한다. 단 해당 옵션을 위해서는 해당 디바이스가 io_poll을 사용할 수 있도록 세팅 해야한다 ([참조](https://github.com/Csoyee/documents/blob/master/Linux_Setting/io_polling.md)).


- `hipri`: 해당 옵션이 set 되면 fio는 polled IO completion 을 사용한다. 본래 io completion 시에 interrupt 를 통해서 IO completion이 되었음을 알린 반면 polled completion은 IO completion 시 까지 polling을 한다.


### KERNEL SIDE POLLING

IO_URING은 IO submit 과정에서 `io_uring_enter` 을 콜한다. kernel side polling이 활성화 되면 응용에서 해당 콜을 할 필요 없이 커널에서 자동으로 새로운 entry를 알아채고 처리한다. 이를 위해서 별도의 `io_uring` kernel thread가 생기게 된다. 

- `sqthread_poll`: If this option is set, the act of submitting IO will be done by a polling thread in the kernel. This frees up cycles for fio, at the cost of using more CPU in the system.
- `sqthread_poll_cpu`: When sqthread_poll is set, this option provides a way to define which CPU should be used for the polling thread.



