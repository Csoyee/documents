# file system tuning (tune2fs)

`tune2fs` 는 ext2/ext3/ext4 파일시스템 파라미터를 조정할 수 있는 명령어이다. 
파일시스템 파라미터를 변경함으로써 시스템 안정성을 높이거나 성능을 향상시킬 수 있다.

> sudo 권한으로 사용 해야하지만 아래의 예시 명령에서는 편의를 위해 sudo 를 쓰지 않음...

### 현재 parameter 확인하기
`-l` 옵션을 통해 현재 파일시스템 파라미터를 확인할 수 있으며 결과 값은 아래와 같다.
```bash
$> tune2fs -l [device name]
tune2fs 1.42.9 (4-Feb-2014)
Filesystem volume name:   <none>
Last mounted on:          /
Filesystem UUID:          84b4859f-2d5e-4f95-a134-8e07d3c41a85
Filesystem magic number:  0xEF53
Filesystem revision #:    1 (dynamic)
Filesystem features:      has_journal ext_attr resize_inode dir_index filetype needs_recovery extent flex_bg sparse_super large_file huge_file uninit_bg dir_nlink extra_isize
Filesystem flags:         signed_directory_hash 
Default mount options:    user_xattr acl
Filesystem state:         clean
Errors behavior:          Continue
Filesystem OS type:       Linux
Inode count:              56983552
Block count:              227911424
Reserved block count:     11395571
Free blocks:              32769407
Free inodes:              55575225
First block:              0
Block size:               4096
Fragment size:            4096
Reserved GDT blocks:      969
Blocks per group:         32768
Fragments per group:      32768
Inodes per group:         8192
Inode blocks per group:   512
Flex block group size:    16
Filesystem created:       Thu Jan  4 13:11:26 2018
Last mount time:          Wed Jul 10 14:54:16 2019
Last write time:          Wed Jul 10 14:54:15 2019
Mount count:              104
Maximum mount count:      -1
Last checked:             Thu Jan  4 13:11:26 2018
Check interval:           0 (<none>)
Lifetime writes:          3724 GB
Reserved blocks uid:      0 (user root)
Reserved blocks gid:      0 (group root)
First inode:              11
Inode size:               256
Required extra isize:     28
Desired extra isize:      28
Journal inode:            8
First orphan inode:       41156700
Default directory hash:   half_md4
Directory Hash Seed:      0d1f780a-4d81-46a9-ac4e-2418dd9f3e2f
Journal backup:           inode blocks
```

### 옵션

#### reserved block 조정
- reserved block은 reserved 되어서 filesystem fragmentation 을 피하고 `syslogd`와 같은 system damen 가 정상적으로 동작할 수 있도록 하는 역할을 한다. 즉 시스템 안정성을 높이기 위해서 reserve 해놓은 영역으로 default 퍼센트는 5% 이다.
- reserved block 을 해제하여 user 이 사용하게 하기 위한 방법은 2가지가 있다.
```bash
# block 개수 조정
$> tune2fs -r 0 [device name]
# block percent 조정
$> tune2fs -m 0 [device name]
```
