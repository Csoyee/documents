# Getting Stated with IO_Uring API

Reference: [io_uring document](http://kernel.dk/io_uring.pdf) / [FIO repo](https://github.com/axboe/fio)
Linux Code: [Link](https://github.com/torvalds/linux/blob/master/include/uapi/linux/io_uring.h)

본 문서는 IO uring API 사용을 위해 정리된 문서로 FIO 에서 IO_Uring 을 구현한 코드가 있어 주로 FIO repository 를 참조함.


## IO_Uring Overview

`IO_Uring` 은 Linux Kernel 5.1 버전부터 도입된 새로운 Linux IO 인터페이스이다. 리눅스 IO 는 크게 동기적/비동기적 IO 로 분류된다. `IO_Uring` 은 비동기적 IO 인터페이스이다.
기존의 비동기 IO 인 `libaio` 와 비교하여 buffered write 가 가능하며, mmap 을 활용하여 응용과 커널 사이에 메모리를 공유하여 메모리 복사를 줄이고 locking 없이 해당 메모리를 사용할 수 있도록 설계하였다. (자세한 내용은 문서 참조)

IO_Uring 의 핵심 자료구조는 Submission/Completion Queue 이다. 이 queue 의 쌍을 통해 응용이 커널에 내린 submitted request 와 처리가 완료되어 커널에서 응용에게 알린 completed request 를 관리한다. 


## API

### Data Structure
[referenced sorce code](https://github.com/axboe/fio/blob/master/os/linux/io_uring.h)
 
앞서 언급한 바와 같이 IO_Uring 에서는 두 쌍의 Ring 을 사용한다. 이 두개의 Ring (SQ, CQ) 의 엔트리 구조체는 아래와 같다.

#### SQ Entrie (SQE)

```bash
struct io_uring_sqe {
	__u8	opcode;		/* type of operation for this sqe */
	__u8	flags;		/* IOSQE_ flags */
	__u16	ioprio;		/* ioprio for the request */
	__s32	fd;		/* file descriptor to do IO on */
	__u64	off;		/* offset into file */
	__u64	addr;		/* pointer to buffer or iovecs */
	__u32	len;		/* buffer size or number of iovecs */
	union {
		__kernel_rwf_t	rw_flags;
		__u32		fsync_flags;
		__u16		poll_events;
		__u32		sync_range_flags;
	};
	__u64	user_data;	/* data to be passed back at completion time */
	union {
		__u16	buf_index;	/* index into fixed buffers, if used */
		__u64	__pad2[3];
	};
};
```

FIO 에서 `readv` operation 을 보내기 위해서 sqe 를 세팅하는 과정을 확인해보자. `io_uring` 의 optimization factor 인 fixed buffer 을 사용하지 않을 때의 코드이다.
> 이 때 `io_u` 는 FIO 에서 io unit 으로 사용하는 structure 이고, ld 는 io_uring data 관리를 위한 것으로 자체적으로 정의한 ioring_data 자료구조를 사용한다.
```bash
sqe->fd = f->fd;

if (io_u->ddir == DDIR_READ)
	sqe->opcode = IORING_OP_READV;

sqe->addr = (unsigned long) &ld->iovecs[io_u->index];
sqe->len = 1;

sqe->off = io_u->offset;

sqe->user_data = (unsigned long) io_u;
```


#### CQ Entrie
```bash
struct io_uring_cqe {
	__u64	user_data;	/* sqe->data submission passed back */
	__s32	res;		/* result code for this event */
	__u32	flags;
};
```
FIO io_uring engine 코드의 `fio_ioring_event` 함수를 보면 받아온 sq entrie 처리에 대한 코드가 있다.



### io_uring interface

#### io_uring_setup
io_uring 인스턴스를 세팅하는 함수로 아래와 같이 사용된다.

```bash
int io_uring_setup (unsigned entries, struct io_uring_params *params);
```

파라미터에 대해서 알아보면 그 자료구조는 다음과 같다.

```bash
struct io_uring_params {
  __u32 sq_entries;
  __u32 cq_entries;
  __u32 flags;
  __u32 sq_thread_cpu;
  __u32 sq_thread_idle;
  __u32 resv[5];
  struct io_sqring_offsets sq_off;
  struct io_cqring_offsets cq_off;
};
``` 

`sq_entries` 는 커널에 의해서 설정되며 application 에 몇 개의 entrie 가 지원되는지 알려준다. 동일하게 `cq_entries` 역시 CQ ring 사이즈를 알려주는 변수이다. `sq_off`, `cq_off` 는 io_uring 의 기본적인 communication 의 setup 을 위해서 꼭 필요하다. flag는 별도의 optimized parameter 로 fio 코드를 보면 확인할 수 있다 (polling, sqpoll_thread ... 세팅 가능).

`sq_off`, `cq_off` 에 대해서 알아보자. `sq_off`, `cq_off` 는 커널과 응용 사이에 공유되는 변수로 응용은 `sq_off` 멤버를 사용해서 다양한 ring members 에 대한 offset 을 얻을 수 있다.
```bash
struct io_sqring_offsets {
	__u32 head;
	__u32 tail;
	__u32 ring_mask;
	__u32 ring_entries;
	__u32 flags;
	__u32 dropped;
	__u32 array;
	__u32 resv1;
	__u64 resv2;
};
```

해당 메모리에 접근하기 위해서 application 은 `mmap` 을 불러야하며 io_uring API 는 응용이 사용할 mmap offset 를 정의하고 있다.
```bash
#define IORING_OFF_SQ_RING 0ULL
#define IORING_OFF_CQ_RING 0x8000000ULL
#define IORING_OFF_SQES 0x10000000ULL
```

`IORING_OFF_SQ_RING` 은 SQ ring 을 응용의 memory space 에 매핑하기 위해서 사용되고 `IORING_OFF_CQ_RING` 는 CQ ring 에 대해 동일한 목적으로 사용된다.
`IORING_OFF_SQES` 는 sqe array 를 위해 사용된다. (sqe 는 indirect mapping 을 함)


FIO 에서 setup 하는 코드는 io_uring engine 코드의 `fio_ioring_queue_init` 함수에 구현되어있다.

```bash
	struct io_uring_params p;
	int ret;

	memset(&p, 0, sizeof(p));

	if (o->hipri)
		p.flags |= IORING_SETUP_IOPOLL;
	if (o->sqpoll_thread) {
		p.flags |= IORING_SETUP_SQPOLL;
		if (o->sqpoll_set) {
			p.flags |= IORING_SETUP_SQ_AFF;
			p.sq_thread_cpu = o->sqpoll_cpu;
		}
	}

	ret = syscall(__NR_sys_io_uring_setup, depth, &p);
	if (ret < 0)
		return ret;

	ld->ring_fd = ret;

```

위의 코드에서는 optimization 을 위해서 별도의 flag 를 설정한다. 이 때 `hipri` 옵션은 polling 모드에 대한 flag 로 [linux의 io_uring.h](https://github.com/torvalds/linux/blob/master/include/uapi/linux/io_uring.h) 에도 정의되어 있다.
 

#### io_uring_enter

응용은 또한 커널에게 request 를 만들었음을 알려햐 한다. 이는 아래의 시스템 콜을 통해서 이뤄진다.

```bash
int io_uring_enter (unsigned int fd, unsigned int to_submit,
                    unsigned int min_complete, unsinged int flags, 
                    sigset_t sig);
```

`fd` 는 `io_uring_setup` 함수의 return 값으로 받은 ring file descriptor 이다. `to_submit` 은 커널에게 준비된 sqe 의 개수를 알려준다. 자세한 내용은 문서와 코드를 참조하면 확인할 수 있다.




### 그냥 참조용 libaio 자료

[libaio api 참조자료](https://janzhou.org/2011/10/18/libaio-example.html)
[libaio io_submit man page](http://man7.org/linux/man-pages/man2/io_submit.2.html)
