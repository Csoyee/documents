# F2FS 

[관련문서](https://github.com/torvalds/linux/blob/master/Documentation/filesystems/f2fs.txt)

## f2fs tool 설치
```bash
$> sudo apt-get install f2fs-tools
```

## f2fs 파일시스템 생성
```bash
$> sudo mkfs.f2fs 
```
- option 추가 예정

## f2fs module 로드
- mount 이전에 수동으로 커널모듈을 로드 해야한다.
```bash
$> modprobe f2fs
```

## mount
```bash
$> sudo mount -t f2fs [device name] [mount path]

# discard option mount (default: discard off)
$> sudo mount -t f2fs -odiscard [device name] [mount path]
```

