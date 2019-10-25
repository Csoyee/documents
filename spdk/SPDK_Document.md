# SPDK Document

Reference: [spdk document](https://spdk.io/doc/about.html)

## What is SPDK

Storage Performance Development Kit (SPDK) 는 높은 성능과, 확장성(saclable) 을 갖는 user-mode storage 응용을 만들 수 있는 라이브보리를 위한 tool 을 제공한다. SPDK 는 아래의 핵심 기술들을 통해서 높은 성능을 이룩하였다.

- 필요로하는 모든 드라이버들을 **유저스페이스로 옮김** 으로써 시스템 콜의 사용을 피하고 application 에서 zero-copy access를 할 수 있다.
- IO completion 시에 interrupt 방식이 아닌 **Polling** 방식을 사용함으로써 latency 와 latency 편차를 낮춘다.
- I/O path 에서 모든 lock 을 피한다. **lockless**

SPDK 의 핵심은 user space, polled-mode, asynchronous, lockless Nvme 드라이버라는 점이다. 이러한 특성들을 통해서 zero-copy 와 높은 하드웨어 접근 병렬성을 응용에게 제공한다. 



## User Space Drivers

### Controlling Hardware From User Space

대부분의 SPDK 문서들은 *user space drivers* 을 언급하고 있기 때문에 이 것이 기술적으로 무엇을 의미하는지 이해하는 것은 아주 중요하다. 먼저 *driver* 은 컴퓨터에 부착된 특정 디바이스를 직접 통제하는 소프트웨어 이다. 두 번째로, OS 는 시스템의 가상 메모리를 두 가지 카페고리로 분류한다 - kernel space and user space. 이러한 분리는 *protected rings* 이라는 CPU 자체 기능에 의해서 지원된다. 일반적으로 드라이버는 커널 스페이스에서 수행된다. SPDK 는 이와 다르게 유저 스페이스에서 수행됨에도 불구하고 직접 하드웨어 디바이스와 소통할 수 있도록 설계된 드라이버를 가지고 있다. 

SPDK 가 디바이스를 통제할 수 있게 하기 위해서는 먼저 OS 가 그 통제권을 포기하도록 지시해야 한다. 이는 커널 드라이버를 디바이스로 부터 *unbinding* 한다 라고 말한다 ([참조](https://lwn.net/Articles/143397/)). SPDK 는 리눅스에서 제공되는 두 개의 특수한 드라이버 중 하나에 *rebind* 한다 (uio / vfio). 이 두 드라이버는 특정 장치가 해당 드라이버에 바인딩되어 있음을 OS 에 알리기 때문에 자동으로 디폴트 드라이버로 리바인딩하려고 하지 않는다는 점에서 dummy 드라이버이다. 그들은 실제로 hardware 를 initialize 하지 않을 뿐더러 해당 디바이스가 어떤 종류의 디바이스인지도 알려고하지 않는다. Uio 와 Vfio 의 가장 큰 차이는 Vfio 는 user space 드라이버에서 메모리 보안을 보장해주는 하드웨어인 IOMMU 를 프로그래밍할 수 있다는 점이다. 

일반 디바이스가 OS 시스템 커널로부터 *unbind* 되면, OS 시스템은 해당 디바이스를 사용할 수 없다. 예를 들어서, 만일 사용자가 NVMe device 를 리눅스에서 *unbind* 하면 이에 해당되는 디바이스(i.e., /dev/nvme0n1) 가 사라진다. 이는 해당 디바이스로 마운트 되어있던 파일 시스템 역시 사라지고 커널 파일시스템이 더이상 해당 디바이스와 소통할 수 없을을 의미한다. 대신에 SPDK는 OS storage 스택에 포함된 대부분의 레이어를 C 라이브러리 형태로 재구현하여 제공한다. 해당 레이어들은 device abstraction 레이어, block allocators, filesystem-like 요소등을 포함한다.

유저 스페이스 드라이버는 uio 나 vfio 를 이용하여 디바이스의 PCI bar 을 프로세스에 매핑한다. 일례로, SPDK 의 NVMe Driver 은 BAR을 NVMe device 에 매핑하여 디바이스 초기화나 queue pair 생성, I/O 전송까지 NvMe 스펙에 맞추어서 수행한다.


### Interrupt

SPDK 는 디바이스 completion 을 받을 때 interrupt 를 기다리는 방식이 아닌 polling 방법을 사용한다. Polling 을 사용하는 많은 이유들이 있다.
1. 실용성의 측면에서 interrupt 핸들링을 유저 스페이스에서 수행하도록 하는 것이 어렵다.
2. interrupt 방식은 context switch 를 강제적으로 해야하기 때문에 상당한 오버헤드를 가진다..

### Threading
NVMe 디바이스는 하드웨어에 request 를 보낼 때 여러 개의 queue 를 사용한다. 각각의 queue 는 coordination 없이 접근할 수 있기 때문에 소프트웨어는 디바이스에 멀티 쓰레드 요청을 보낼 때 lock 없이 보낼 수 있다. 대부분의 커널 드라이버는 코어당 하드웨어 큐를 선정해서 매핑하고 request 가 요청될 때 현재 쓰레드가 수행되고 있는 코어에 맞는 하드웨어 큐를 찾는다. 종종 이 과정에서 동일 코어에서 수행되는 thread 로 인한 thread preemption 을 막기 위해서lock 을 잡거나 일시적으로 interrupt 를 막기도한다. 

유저 스페이스 드라이버는 반면에 단일 application 에 임베디드 되어 있다. 특정 응용은 자기 스스로 thread 를 만들어 내기 때문에 정확히 몇개의 thread 가 있는지 알고있다. 따라서 SPDK 드라이버는 hardware queue들을 응용에 직접적으로 보여주고 한번에 하나의 프로세스나 쓰레드만 수행할 수 있도록 한다. 

