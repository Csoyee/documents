# Make Filesystem in linux

## XFS

### xfs 설치
```bash
$> sudo apt-get install xfsdump
```

### f2fs 파일시스템 생성
```bash
$ sudo mkfs.xfs [device name]
```

### mount
- 리눅스 XFS 마운트 시에 `nobarrier` option deprecated 됨 ([관련 링크](https://patchwork.kernel.org/patch/10487561/))

```bash
$ sudo mount -t xfs [device name] [data directory]
```


## F2FS 

[관련문서](https://github.com/torvalds/linux/blob/master/Documentation/filesystems/f2fs.txt)

### f2fs tool 설치
```bash
$> sudo apt-get install f2fs-tools
```

### f2fs 파일시스템 생성
```bash
$> sudo mkfs.f2fs [device name]
```
- option 추가 예정

### f2fs module 로드
- mount 이전에 수동으로 커널모듈을 로드 해야한다.
```bash
$> modprobe f2fs
```

### mount
```bash
$> sudo mount -t f2fs [device name] [mount path]

# discard option mount (default: discard off)
$> sudo mount -t f2fs -odiscard [device name] [mount path]
```

### F2FS status 확인하는 법

```bash
$> /sys/kernel/debug/f2fs/status
```
- 위 파일에서 file system utilization, 파티션 정보, GC 정보등을 확인할 수 있다.
