# Open Channel SSD on Cosmos+


## Prerequisites
- linux version check / config check (pblk, nvm)
- nvme-cli 

## Setup

1. Cosmos+ SSD 가 open channel SSD 로서 동작하기 위한 펌웨어는 다음 [레포지토리](https://github.com/Cosmos-OpenSSD/OCSSD-plus)에 있다. [Cosmos+ Tutorial 자료](https://github.com/Cosmos-OpenSSD/Cosmos-plus-OpenSSD/blob/master/doc/Cosmos%2B%20OpenSSD%202017%20Tutorial.pdf)를 참조하여 펌웨어를 올린다.

2. 리눅스 host PC 를 리부트한다. (이 때 linux 버전에 유의하자!)

3. NVMe Device 가 제대로 인식되었는지 확인한다.
```bash
$ sudo nvme list 
Node             SN                   Model                                    Namespace Usage                      Format           FW Rev  
---------------- -------------------- ---------------------------------------- --------- -------------------------- ---------------- --------
/dev/nvme0n1     SSDD515T             Cosmos+ OpenSSD                          134217728 549.76  GB / 549.76  GB      4 KiB + 16 B   TYPE0006

$ sudo nvme lnvm list
Number of devices: 1
Device          Block manager   Version
nvme0n1         gennvm          (1,0,0)
```

## 테스트
`nvme-cli` 를 활용하여 bbt를 제대로 가져오는지 확인하면 
```bash
$ sudo nvme lnvm-diag-bbtbl /dev/nvme0n1 -c 0
LightNVM Bad Block Stats:
verid    : 0x1
tblks    : 8192
tfact    : 9
tgrown   : 0
tdresv   : 0
thresv   : 0
```

위와 같이 정상적으로 동작하는 것을 알 수 있다.

## TODO
device 와 target 을 initialize 과정에서 line initilize failed 원인 찾기 (ISSUE [#5](https://github.com/Csoyee/documents/issues/5))

```bash
$ sudo nvme lnvm inti -d nvme0n1

$ sudo nvme lnvm create -d nvme0n1 -b 0 -e 7 -n mydev -t pblk 
Creation of target failed. Please see dmesg

$ dmesg
[ 1018.348721] pblk mydev: could not initialize lines
```
