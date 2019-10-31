# SPDK Document

Reference: [spdk document](https://spdk.io/doc/about.html), [spdk paper](https://ieeexplore.ieee.org/abstract/document/8241103)

---
# Index
- [What is SPDK](#What-is-SPDK)
- [System Design and implementation](#System-Design-and-implementation)
- [User Space Drivers](#User-Space-Drivers)
- [Direct Memory Access From User Space ](#Direct-Memory-Access-From-User-Space)
- [Flash Translation Layer](#Flash-Translation-Layer)
---

## What is SPDK

Storage Performance Development Kit (SPDK) 는 높은 성능과, 확장성(saclable) 을 갖는 user-mode storage 응용을 만들 수 있는 라이브보리를 위한 tool 을 제공한다. SPDK 는 아래의 핵심 기술들을 통해서 높은 성능을 이룩하였다.

- 필요로하는 모든 드라이버들을 **유저스페이스로 옮김** 으로써 시스템 콜의 사용을 피하고 application 에서 zero-copy access를 할 수 있다.
- IO completion 시에 interrupt 방식이 아닌 **Polling** 방식을 사용함으로써 latency 와 latency 편차를 낮춘다.
- I/O path 에서 모든 lock 을 피한다. **lockless**

SPDK 의 핵심은 user space, polled-mode, asynchronous, lockless Nvme 드라이버라는 점이다. 이러한 특성들을 통해서 zero-copy 와 높은 하드웨어 접근 병렬성을 응용에게 제공한다. 

## System Design and implementation 

SPDK 는 커스터마이징된 고성능의 스토리지 응용을 빌드하는데 필요한 라이브러리들읠 모음이다. SPDK 는 크게 4개의 주요 구성요소로 이루어져있다. (i,e., drivers, app scheduling, storage devices and storage protocols)

1. app scheduling : 응용에 이벤트 프레임워크를 제공한다. 
2. drivers : user space polled mode NVMe driver 
3. storaged devices : driver 을 통해 보여지는 장치를 추상화하여 위의 스토리지 응용에 block I/O 인터페이스를 제공한다. 
4. storage protocols: 다양한 스토리지 프로토콜을 제공하기 위해 SPDK 프레임워크 위에 구현된 응용 


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


## Direct Memory Access From User Space 

본 내용은 왜 SPDK 로 전달되는 데이터버퍼가 `spdk_dma_malloc` 함수로 불려야 하며 SPDK 에서 메모리 관리를 위해서 DPDK에서 입증된 기본 기능에 의존하는지에 대해서 설명한다.

컴퓨터 플랫폼은 일반적으로 페이지라고 불리는 4KB 의 세그먼트 단위로 물리적 메모리를 분할한다. 0 부터 N 까지의 페이지는 이용가능한 메모리의 처음부터 시작한다. 그 후 OS 는 임의의 복잡한 맽핑을 사용하여 실제 페이지 위에 4KB 의 가상 메모리 페이지를 오버레이한다. 

피지컬 메모리는 각각의 메모리 채널이 정해진 양의 bandwidth 를 제공하는 체널에 연결된다. 전체 메모리 BW를 늘리기 위해서는 피지컬 메모리는 종종 자동으로 채널들로 퍼져서 관리된다. 예를 들어서 0번 페이지는 0번 채널에, 1번 페이지는 1번 채널에 할당되는 방식이다. 이렇게 수행하면 메모리를 순차적으로 적으면 자동적으로 모든 가능한 채널을 사용하게 된다. 실제로 interleaving 은 전체 페이지보다 훨씬 더 세분화된 수준에서 이뤄진다. 

최근의 컴퓨터 플랫폼은 Memory Management Unit(MMU) 상에서 메모리 변환 (virtual to physical) 에 대한 하드웨어 가속을 지원한다. MMU 는 종종 여러 개의 다른 페이지 사이즈를 지원한다. 최근의 x86_64 시스템에서는 4KB, 2MB, 1GB 의 페이지가 지원된다. 일반적으로 OS 에서는 4KB 의 페이지를 디폴트로 갖는다.

NVMe 장치는 데이터를 DMA 를 이용하여 시스템 메모리로 전송한다. 특히 그들은 PCI 버스에 데이터 전송을 효청하면서 메세지를 전송한다. IOMMU 가 없으면 이러한 메세지는 물리적인 메모리 주소를 보유한다. 이러한 데이터 전송은 CPU의 개입없이 이뤄지며 MMU는 일관성있는 메모리 접근에 대한 책임을 갖는다.

NVMe 장치는 또한 이러한 전송을 위해서 추가적인 요구사항을 가지기도 한다. NVMe 1.0 스텍에서는 모든 물리적인 메모리가 PRP list 라고 불리우는 형태로 설명될 수 있어야 했다. PRP list 로 설명되기 위해서는 아래의 특성을 가져야 한다.

- 메모리가 4KB 페이지로 쪼개질 수 있어야 하며, 이는 device pages 라고 부른다..
- 첫 번째 device page 는 4B로 정렬된 주소로 시작하는 부분 페이지일 수 있다. 이는 실제 페이지의 끝까지 확장될 수 있지만 그 이상으로 확장될 수 없다.
- 만일 한 개 이상의 device page 가 있으면 첫 번째 디바이스 페이지는 4KB 페이지 범위 내에서 끝나야 한다.
- 마지막 device pages 는 4KB boundary 에 시작되어야 하지만 4KB page boundary 에서 끝날 필요는 없다.

NVMe 1.1 스펙에서는 scatter gather list 를 추가적으로 제공했으나 이는 선택적이며 오늘날 사용가능한 대부분은 장치들은 사실상 이를 제공하지 않는다.

User space drvier 는 일반 프로세스의 컨텍스트에서 실행되기 때문에 가상 메모리에 액세스할 수 있따. 물리적 주소로 device 를 제대로 프로그래밍하기 위해서는 주소 변환 방식에 대한 구현 사항이 필요하다.

Linux 에서 주소 변환을 하는 가장 쉬운 방법은 프로세스 내에서 /proc/self/pagemap 을 검사하는 것이다. 해당 파일은 virtrual->physical 주소 변환에 대한 정보를 보유하고 있다. Linux 4.0 에서는 해당 파일에 접근하기 위해서는 root 권한을 필요로 하지만 OS 는 해당 주소변환이 스태틱하다고 완전히 보장할 수 없다. OS 는 PCI 디바이스가 직접적으로 데이터를 물리적인 주소에 전달하고 있는지 확인할 길이 없다. 만일 OS 가 mapping 이 수정될 수 없는 페이지를 지정하면 이는 pinning page 이다. 

virtual->physical 매핑이 바뀔 수 있는 이유는 많다. 지금까지 가장 흔한 이유는 페이지 스와핑 떄문이다. 하지만 OS 는 compaction 을 수행하는 과정에서도 page 를 이동시킨다. 몇몇 OS 는 또한 메모리 압축을 수행하기도 한다. 

SPDK 는 pinned memory 를 할당하기 위해서 DPDK 에 의존한다. 리눅스에서 DPDK 는 *hugepages* 를 할당하는 방식으로 이를 수행한다. 리눅스 커널은 *hugepages* 를 4KB 페이지와 다르게 다룬다. 특히 OS 는 해당 데이터의 물리적인 위치를 절대로 바꾸지 않는다. 이는 의도적인 것이 아니고 이에 따라 미래 버전에서 수정될 수 있으나 몇 년동안 이와 같이 유지되어 왔다. 

위의 설명을 통해 우리는 왜 SPDK 가 `spdk_dma_malloc` 을 통해서 databuffer 을 전송해야하는지 알 수 있다. 이는 해당 버퍼가 pinning 되어서 이에 대한 물리적 주소를 알고있어야하기 때문이다.

### IOMMU Support

많은 플랫폼들은 I/O Mamory Management Unit (IOMMU) 라고 불리우는 별도의 하드웨어가 별도로 추가되어 있다. IOMMU 는 일반 MMU 와 비슷하나 주변 장치에 가상의 주소를 제공한다는 점이 차이점이다. MMU 는 시스템 프로세스의 V2P mapping 알고 있기 때문에 IOMMU 는 특정 장치를 이러한 매핑 중 하나에 연결한 다음에 사용자가 프로세스에서 가상 주소에 임의의 버스 주소를 할당할 수 있도록 허용한다. 즉, PCI 디바이스와 시스템 메모리 간의 모든 DMA 작업은 IOMMU를  통해서 bus address 를 virtual address 로 virtual address 를 physical address 로 변환되도록 한다. 이는 OS 가 virtual to physical address mapping 을 현재의 DMA 작업에 대한 방해 없이 수행할게 한다. 리눅스는 vfio-pic 라는 디바이스 드라이버를 제공하여 유저가 현재의 process 를 IOMMU 로 설정할 수 있게 해준다. 

이는 user space process 안팎으로 DMA 작업을 수행하기 위한 미래형 하드웨어 가속 솔루션으로 SPDK 와 DPDK 의 메모리 관리 방법의 장기적인 기초가 된다. 우리는 응용이 vfio 와 IOMMU 를 사용하여 배포하는 것을 추천하다. 

## Flash Translation Layer
Flash Translation Layer 은 Open Channel 인터페이스를 통하여 non-block SSD 상에서 블록 디바이스 접근을 할 수 있다. FTL 모듈을 사용하기 위해서는 Open Channel SSD 가 필요하다. 가장 쉽게 세팅할 수 있는 것은 QEMU 를 통해서 애뮬레이션을 하는 것이다. Open Channel support 를 제공하는 QEMU 는 [spk-3.0.0](https://github.com/spdk/qemu/tree/spdk-3.0.0) 에 있다. 


### Terminology
#### Logical to physical address map
L2P mapping 이라고도 불리우며 논리적 주소와 디스크 상의 물리적 주소 간의 매핑을 의미한다. LBA 는 0부터 사용가능한 블록만큼의 범위를 가지며 디바이스 상의 여분의 블록(spare block) 들은 데이터 defragmentation 에 사용되기 위해서 필요한 오프라인으로 전환된 chunck 들을 의미한다.

#### Band
 Band 는 chunck의 묶음이다. 각각의 band 는 서로 다른 병렬 유닛(parallel unit) 에 속한다. Band 로 내려오는 모든 쓰기는 동일한 패턴을 가진다 - 특정 chunk 에 logical block 에대한 배치 요청이 내려오고 다른 배치가 다음 chunch 로 내려온다. 이러한 패턴을 통해 쓰기 operation 들이 서로 다른 chunck 에서 독립적으로 수행될 수 있기 때문에 쓰기 작업의 병렬성을 보장한다. 각각의 band 는 band 를 구성하는 LBA, 각각의 validity 등을 관리한다. L2P mapping d은 가장 오래된 band 부터 가장 어린 band 에 걸쳐서 SSD 를 읽음으로써 복원될 수 있다. 
 Address map 과 valid amp 은 밴드의 메타데이터의 일부로서 다른 메타데이터와 함께 위치한다. 메타데이터는 크게 2가지 (head and tail) 파트로 나누어진다.
 - the head part: band 를 여는 시점에 이미 알고있던 정보를 가지고 있다. (i.e., 디바이스 UUID, band 번호 ...) Head part는 말 그대로 band 의 맨 앞에 존재한다.
 - the tail part: address map 과 valid map 을 가지고 있으며 band 의 가장 뒤에 존재한다.
 
 밴드는 순차적으로 쓰이며 band 다 쓰여지기 전에 chunk 가 지워져야한다 (쓸 수 있는 영역을 확보하기 위해서). 이 때 band 는 PREP 상태로 간주된다. 해당 상태가 끝나면 band 는 OPENING 상태로 변하게 된다. OPENING 상태에서는 head metadata 가 쓰여진다. 그 후 band 는 OPEN 상태로 변해서 실제 유저가 해당 밴드에 쓰기를 수행할 수 있다. 만일 모든 사용 가능한 영역이 꽉 차면 tail metadata 가 쓰여지고 이 때가 Closing state 이다. 이 상태가 끝나면 band는 CLOSED 상태가 된다. 
 
 #### Ring write Buffer
 SSD 의 가장 작은 쓰기 단이가 여러 개의 block size 일 수 있기 때문에 단일 블록 쓰기를 지원하기 위해서 데이터는 버퍼링 되어야 한다. 쓰기 버퍼는 이러한 문제에 대한 해결책이다. 쓰기 버퍼는 미리 할당된 버퍼인 여러개의 batches 로 구성된다. 각각의 batch 는 SSD 에 하나만 전송할 수 있다. 단일 batch 는 블록 사이즈의 버퍼 엔트리로 나누어진다. 
 
 만일 쓰기가 스케쥴링되어 내려오면 해당 쓰기는 각각의 블록에 대한 엔트리를 확보하고 해당 데이터를 버퍼에 복사해야한다. 모든 블록이 복사되면 해당 쓰기는 종료된 것으로 처리된다. 
 
 #### Deframentation and relocation
 
 동일한 LBA 에 대한 쓰기가 이전의 물리적 위치를 무효화하기 때문에 밴드 내의 몇몇 블록들은 기본적으로 공간을 낭비하는 오래된 데이터를 가질 수 있다. 이미 쓰인 블록을 덮어쓰기 할 수 있는 방법은 없기 때문에 해당 데이터는 모든 chunck 가 리셋될 때까지 머물러야 한다. 이로 인해서 모든 band가 유효한 데이터를 가지고 있어서 어떤 band 도 지워질 수 있는 상황이 발생하고 이로 인해서 더 이상 write 를 수행할 수 없게 된다. 따라서 유효한 데이터를 이동시키고 모든 band 를 무효화하여 다시 쓸 수 있도록 하는 방법이 필요하다 .

데이터 재배치를 담당하는 모듈은 `reloc` 이라고도 불린다. 만일 밴드가 degfragmentation 을 하도록 선택되거나 ANS(asynchronous NAND mgmt) 이벤트를 받으면 적절한 블록들이 이동되어야 한다고 마킹된다. `reloc` 모듈은 그렇게 마킹된 블록들을 가지는 밴드에서 validity 를 체크한다음에 해당 데이터 들이 여전히 유효한 경우 복사한다. 


### Usage

TODO, 아래 부분 해보기!

#### Prerequisite

SPDK QEMU fork: [spk-3.0.0](https://github.com/spdk/qemu/tree/spdk-3.0.0)

#### Configuring QEMU
- serial: serial number
- lver: OCSSD 표준 버전 (0-disabled, 1-"1.2", 2-"2.0"), libfio 은 2.0 만 지원한다.
- lba_index: 디폴트 LBA 포멧으로 libfio 는 4K 단위의 데이터만 지원한다. 
- lnum_ch: 그룹 개수
- lnum_lun: 병렬 그룹 개수
- lnum_pln: plane 개수
- lpgs_per_blk: chunk 당 페이지의 개수
- lblks_per_pln
- laer_thread_sleep
- lmetadata: metadata file

Example:
```bash
$ /path/to/qemu [OTHER PARAMETERs]\
   -drive format=raw,file=/path/to/data/file,if=none,id=myocssd0
   - device nvme,drvie=myocssd0,serial=deadbeef,lver=2,lba_index=3,lnum_ch=1,lnum_lun=8,lnum_lpn=4,lpgs_per_blk=1536,lsecs_per_pg=4,lblks_per_pln=512,lmetadata=/path/to/md/file
```
예시를 확인하면 디바이스는 1채널 8개의 병렬 유닛, 병렬 유닛당 512 개의 청크, 청크당 24576 (lnum_pln * lpgs_per_blk * lsecs_per_pg) 개의 논리 블록이 세팅되었다. 각각의 논리 블록이 4KB 의 크기를 갖기 384GB (8\*512\*24576\*4096 B) 사이즈의 파일을 생성할 수 있다.
 
 #### Configuring SPDK
 
 드라이브가 제대로 애뮬레이션 되었음을 확인하기 위해서 NVMe identify app 의 출력 결과를 확인하면 된다. 
 
 ```bash
 $ examples/nvme/identify/identify
 =====================================================
NVMe Controller at 0000:00:0a.0 [1d1d:1f1f]
=====================================================
Controller Capabilities/Features
================================
Vendor ID:                             1d1d
Subsystem Vendor ID:                   1af4
Serial Number:                         deadbeef
Model Number:                          QEMU NVMe Ctrl
... other info ...
Namespace OCSSD Geometry
=======================
OC version: maj:2 min:0
... other info ...
Groups (channels): 1
PUs (LUNs) per group: 8
Chunks per LUN: 512
Logical blks per chunk: 24576
... other info ...
```

