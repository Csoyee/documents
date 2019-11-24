# SPDK FTL


Reference: [link](https://spdk.io/doc/ftl.html)

- 이 때 LBA configuration 관련하여 LBA_INDEXDATA 는 level 3 이상으로 세팅 가능 즉 생성되는 OCSSD 의 sector 사이즈가 4K 가 된다. 


## Identify test


```
Starting SPDK v20.01-pre git sha1 b0472ac85 / DPDK 19.08.0 initialization...
[ DPDK EAL parameters: identify --no-shconf -c 0x1 -n 1 -m 0 --log-level=lib.eal:6 --log-level=lib.cryptodev:5 --log-level=user1:6 --base-virtaddr=0x200000000000 --match-allocations --file-prefix=spdk_pid20396 ]
=====================================================
NVMe Controller at 0000:00:04.0 [1d1d:1f1f]
=====================================================
Controller Capabilities/Features
================================
Vendor ID:                             1d1d
Subsystem Vendor ID:                   1af4
Serial Number:                         deadbeef
Model Number:                          QEMU NVMe Ctrl
Firmware Version:                      1.0
Recommended Arb Burst:                 6
IEEE OUI Identifier:                   00 02 b3
Multi-path I/O
  May have multiple subsystem ports:   No
  May be connected to multiple hosts:  No
  Associated with SR-IOV VF:           No
Max Data Transfer Size:                4194304
Max Number of Namespaces:              1
Error Recovery Timeout:                Unlimited
NVMe Specification Version (VS):       1.1
Maximum Queue Entries:                 2048
Contiguous Queues Required:            Yes
Arbitration Mechanisms Supported
  Weighted Round Robin:                Supported
  Vendor Specific:                     Not Supported
Reset Timeout:                         7500 ms
Doorbell Stride:                       4 bytes
NVM Subsystem Reset:                   Not Supported
Command Sets Supported
  NVM Command Set:                     Supported
Boot Partition:                        Not Supported
Memory Page Size Minimum:              4096 bytes
Memory Page Size Maximum:              4096 bytes
Optional Asynchronous Events Supported
  Namespace Attribute Notices:         Not Supported
  Firmware Activation Notices:         Not Supported
128-bit Host Identifier:               Not Supported

Controller Memory Buffer Support
================================
Supported:                             No

Admin Command Set Attributes
============================
Security Send/Receive:                 Not Supported
Format NVM:                            Not Supported
Firmware Activate/Download:            Not Supported
Namespace Management:                  Not Supported
Device Self-Test:                      Not Supported
Directives:                            Not Supported
NVMe-MI:                               Not Supported
Virtualization Management:             Not Supported
Doorbell Buffer Config:                Not Supported
Abort Command Limit:                   4
Async Event Request Limit:             4
Number of Firmware Slots:              N/A
Firmware Slot 1 Read-Only:             N/A
Firmware Update Granularity:           No Information Provided
Per-Namespace SMART Log:               No
Command Effects Log Page:              Not Supported
Get Log Page Extended Data:            Supported
Telemetry Log Pages:                   Not Supported
Error Log Page Entries Supported:      4
Keep Alive:                            Not Supported

NVM Command Set Attributes
==========================
Submission Queue Entry Size
  Max:                       64
  Min:                       64
Completion Queue Entry Size
  Max:                       16
  Min:                       16
Number of Namespaces:        1
Compare Command:             Not Supported
Write Uncorrectable Command: Not Supported
Dataset Management Command:  Not Supported
Write Zeroes Command:        Supported
Set Features Save Field:     Not Supported
Reservations:                Not Supported
Timestamp:                   Not Supported
Volatile Write Cache:        Not Present
Atomic Write Unit (Normal):  1
Atomic Write Unit (PFail):   1
Atomic Compare & Write Unit: 1
Scatter-Gather List
  SGL Command Set:           Not Supported
  SGL Keyed:                 Not Supported
  SGL Bit Bucket Descriptor: Not Supported
  SGL Metadata Pointer:      Not Supported
  Oversized SGL:             Not Supported
  SGL Metadata Address:      Not Supported
  SGL Offset:                Not Supported
  Transport SGL Data Block:  Not Supported
Replay Protected Memory Block:  Not Supported

Firmware Slot Information
=========================
Active slot:                 1
Slot 4 Firmware Revision:    .01.....

Error Log
=========
-----------
Entry: 1
Error Count:            0x1
Submission Queue Id:    0x1
Command Id:             0xbf
Phase Bit:              0
Status Code:            0x40
Status Code Type:       0x0
Do Not Retry:           0
Error Location:         0x30
LBA:                    0x0
Namespace:              0x1
Vendor Log Page:        0x0
-----------
Entry: 2
Error Count:            0x2
Submission Queue Id:    0x1
Command Id:             0xbf
Phase Bit:              0
Status Code:            0x40
Status Code Type:       0x0
Do Not Retry:           0
Error Location:         0x30
LBA:                    0x0
Namespace:              0x1
Vendor Log Page:        0x0

Arbitration
===========
Arbitration Burst:           64
Low Priority Weight:         8
Medium Priority Weight:      16
High Priority Weight:        32

Power Management
================
Number of Power States:      1
Current Power State:         Power State #0
Power State #0:  Max Power:  25.00 W
Non-Operational Permissive Mode: Not Supported

Health Information
==================
Critical Warnings:
  Available Spare Space:     WARNING
  Temperature:               OK
  Device Reliability:        OK
  Read Only:                 No
  Volatile Memory Backup:    OK
Current Temperature:         323 Kelvin (50 Celsius)
Temperature Threshold:       333 Kelvin (60 Celsius)
Available Spare:             0%
Available Spare Threshold:   20%
Life Percentage Used:        0%
Data Units Read:             3223552
Data Units Written:          0
Host Read Commands:          130
Host Write Commands:         0
Controller Busy Time:        0 minutes
Power Cycles:                0
Power On Hours:              0 hours
Unsafe Shutdowns:            0
Unrecoverable Media Errors:  0
Lifetime Error Log Entries:  3
Warning Temperature Time:    0 minutes
Critical Temperature Time:   0 minutes

Number of Queues
================
Number of I/O Submission Queues:      63
Number of I/O Completion Queues:      63

OCSSD Media Feedback
=======================
High ECC status:                0
Vector High ECC status:         0

Active Namespaces
=================
Namespace ID:1
Deallocate:                            Not Supported
Deallocated/Unwritten Error:           Not Supported
Deallocated Read Value:                Unknown
Deallocate in Write Zeroes:            Not Supported
Deallocated Guard Field:               0xFFFF
Flush:                                 Not Supported
Reservation:                           Not Supported
Namespace Sharing Capabilities:        Private
Size (in LBAs):                        100663296 (96M)
Capacity (in LBAs):                    100663296 (96M)
Utilization (in LBAs):                 100663296 (96M)
Thin Provisioning:                     Not Supported
Per-NS Atomic Units:                   No
NGUID/EUI64 Never Reused:              No
Number of LBA Formats:                 7
Current LBA Format:                    LBA Format #03
LBA Format #00: Data Size:   512  Metadata Size:     0
LBA Format #01: Data Size:   512  Metadata Size:     8
LBA Format #02: Data Size:   512  Metadata Size:    16
LBA Format #03: Data Size:  4096  Metadata Size:     0
LBA Format #04: Data Size:  4096  Metadata Size:    64
LBA Format #05: Data Size:  4096  Metadata Size:   128
LBA Format #06: Data Size:  4096  Metadata Size:    16

Namespace OCSSD Geometry
=======================
OC version:                     maj:2 min:0
LBA format:
  Group bits:                   0
  PU bits:                      3
  Chunk bits:                   9
  Logical block bits:           15
Media and Controller Capabilities:
  Namespace supports Vector Chunk Copy:                 Supported
  Namespace supports multiple resets a free chunk:      Not Supported
Wear-level Index Delta Threshold:                       0
Groups (channels):              1
PUs (LUNs) per group:           8
Chunks per LUN:                 512
Logical blks per chunk:         24576
MIN write size:                 4
OPT write size:                 16
Cache min write size:           16
Max open chunks:                0
Max open chunks per PU:         0

OCSSD Chunk Info Glance
======================
------------
Chunk index:                    0
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   0
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    1
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   32768
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    2
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   65536
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    3
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   98304
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    4
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   131072
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    5
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   163840
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    6
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   196608
Number of blocks in chunk:      24576
Write Pointer:                  0
------------
Chunk index:                    7
Chunk state:                    Free(0x1)
Chunk type (write mode):        Sequential Write
Chunk type (size_deviate):      No
Wear-level Index:               0
Starting LBA:                   229376
Number of blocks in chunk:      24576
Write Pointer:                  0
```


## Hello World Test

Write I/O failed.

## FIO Test   

수행은 되지만 NOTICE msg 가 나옴
```bash
nand_rule: lvnm_rwc: I/O does not respect device write constrains.Sectos send: (1). Min:4 sectors required
```

OCSSD 상의 Sector 사이즈가 4K 이고 lsecs_per_pg=4 로 설정하여 bs 를 16K 로 바꾸어 다시 수행

```bash
nand_rule: previous page state(W) is not (W) for ppa(0x~~)
lnvm_rwc: set written + meta status faild with psl[0] = ppa: ch(0), lun(0), blk(185), pg(578), pl(1), sec(0)
```

TODO >> 문제 원인 파악
