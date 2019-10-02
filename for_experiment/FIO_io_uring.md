# FIO IO Uring Support

[FIO source code](https://github.com/axboe/fio)
Fio 3.13 version 부터 io_uring engine 을 지원.

> upgrade FIO version ! (sksms 3.16.7)
> io_uring 은 커널버전 5.1 이후부터 지원되므로 io_uring test를 위해서는 kernel 버전도 5.1 버전 이후로 맞춰주어야 한다. (나는 5.3)


## How to use io uring
```bash
$> fio [--other options] --io_engine=io_uring 
```

제대로 동작하는지 확인, 나의 경우 ftrace 를 통해서 io_uring call 이 불리는지 확인하였다. 
아래와 같이 `__x64_sys_io_uring_enter`, `io_ring_submit`, `io_get_sqring.isra.21()` 등의 io_uring 관련 시스템 함수가 불린다.

![image](https://user-images.githubusercontent.com/18457707/66024940-2f85ce80-e530-11e9-8c7c-9a2a5686d75b.png)

## IO_URING engine specific option

- hipri: 해당 옵션이 set 되면 fio는 polled IO completion 을 사용한다. 본래 io completion 시에 interrupt 를 통해서 IO completion이 되었음을 알린 반면 polled completion은 IO completion 시 까지 polling을 한다.
- fixedbufs: 만일 direct IO 를 수행하라고 지정한 경우 각각의 IO call 에 대한 page 를 매핑하고 IO가 끝나면 해당 페이지를 release 한다. 만일 해당 옵션이 set 되어있으면 페이지들이 pre-mapped 되어있어서 map/release 오버헤드를 줄일 수 있다.
- registerfiles
- sqthread_poll
- sqthread_poll_cpu
