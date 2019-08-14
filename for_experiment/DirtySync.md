# Dirty Page Sync

[참조](https://brunch.co.kr/@alden/32)

## Dirty 와 관련된 kernel parameters

```bash
$> sudo /sbin/sysctl -a | grep dirty 
vm.dirty_background_bytes = 0
vm.dirty_background_ratio = 5
vm.dirty_bytes = 0
vm.dirty_expire_centisecs = 3000
vm.dirty_ratio = 10
vm.dirty_writeback_centisecs = 500
vm.dirtytime_expire_seconds = 43200
```

- `vm.dirty_background_bytes`: 정해진 값에 도달하면 flush 데몬에 의해 dirty data가 sync 됨 (일반적으로 0으로 disable 해서 사용)
- `vm.dirty_background_ratio`: 전체 메모리 대비 dirty page 의 존재 비율 (전체 메모리가 8G이면 `dirty_background_ratio` 가 5일 때 dirty page 크기가 400M 이상이면 flush)
- `vm.dirty_bytes/ratio`: 같은 작업을 foreground 로 수행
- `vm.dirty_writeback_centisecs` : flush 데몬이 깨어나는 시간 500 --> 5초
- `vm.dirtytime_expire_seconds`: 정해진 시간이 지난 dirty page 들이 싱크됨. 
