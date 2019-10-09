# Polling setup



[reference](https://events.static.linuxfound.org/sites/events/files/slides/lemoal-nvme-polling-vault-2017-final_0.pdf)


## Setting 
sysfs 에서 [queue](https://www.kernel.org/doc/html/latest/block/queue-sysfs.html) 파일에 있는 io_poll 을 통해 enable 할 수 있다. 

```bash
$ echo 1 > /sys/block/nvme0n1/io_poll
```

### Error handling 
`invalid argument` error이 발생한 경우, 커널 파라미터인 `nvme.poll_queues` 룰 0이 아닌 수로 세팅해주어야 한다.

```bash
$ echo 1 > /sys/module/nvme/parameters/poll_queues
```

하지만 이를 세팅하여도 io_poll 똑같은 에러가 발생한다.

### Solve
Kernel nvme driver 에서 Nvme device 를 unbind 한 후 다시 bind 를 해주니 에러가 없어졌다.

### TODO
io_poll 을 1로 설정하고 다시 fio 를 수행하였으나 [ftrace](https://github.com/Csoyee/documents/blob/master/tool/ftrace.md) 를 떴을 때 `do_IRQ function` 이 불리고 `nvme_poll function` 이 불리지 않는 것을 확인함.
