# Nvme-Cli


## READ and WRITE
```bash
$ echo "write new data!" | sudo nvme write /dev/nvme0n1 --start-block=10 --data-size=512 --show-command  
opcode       : 01
flags        : 00
control      : 0000
nblocks      : 0000
rsvd         : 0000
metadata     : 0
addr         : 250f000
slba         : a
dsmgmt       : 00000000
reftag       : 00000000
apptag       : 0000
appmask      : 0000
write: Success
```

위의 명령을 수행하면 어떻게 될까. start-block 은 시작 1ba 를 의미하고 data-size 는 바이트 단위 데이터의 길이를 의미한다. 즉 10번 lba에 512 만큼의 데이터를 쓰게된다.
nvme write 의 경우 읽고 쓸 파일을 제공하지 않으면 기본적으로 stdout 을 인풋으로 사용하기 때문에 본 예시에서는 ehco 를 통해서 데이터를 넣어주었다.

위의 명령을 수행할 때 어떻게 내려가는지 확인하기 위해서 `--show-command` 옵션을 붙였다. opcode 는 nvme specification 에 따라 1번이다. 
하나의 블록에 대한 요청이며 이 때 start-block 번호가 10번이기 대문에 slba 는 'a' 가 된다.

> NLB is zero's base

쓴 데이터를 읽기 위해서 read 를 수행해보겠다.


```bash
$ sudo nvme read /dev/nvme0n1 --start-block=10 --data-size=512 --show-command
opcode       : 02
flags        : 00
control      : 0000
nblocks      : 0000
rsvd         : 0000
metadata     : 0
addr         : 17a8000
slba         : a
dsmgmt       : 00000000
reftag       : 00000000
apptag       : 0000
appmask      : 0000
write new data!
read: Success
```
Read 의 opcode 는 2 번이다. 
마지막에서 두 번째 줄에 제대로 data가 읽혀오는 것을 알 수 있다.


## IO-PASSTHRU
io-passthru 를 통해 유저가 정의한 IO command 를 특정 디바이스에 보낼 수 있다. 
(이 때 만일 해당 command 를 admin command 로 내리고 싶다면 io-passthru 가 아니라 admin-passthru 를 확인!)

### options
```
  [  --opcode=<NUM>, -o <NUM> ]         --- opcode (required)
  [  --flags=<NUM>, -f <NUM> ]          --- command flags
  [  --prefill=<NUM>, -p <NUM> ]        --- prefill buffer with known
                                            byte-value, default 0
  [  --rsvd=<NUM>, -R <NUM> ]           --- value for reserved field
  [  --namespace-id=<NUM>, -n <NUM> ]   --- desired namespace
  [  --data-len=<NUM>, -l <NUM> ]       --- data I/O length (bytes)
  [  --metadata-len=<NUM>, -m <NUM> ]   --- metadata seg. length (bytes)
  [  --timeout=<NUM>, -t <NUM> ]        --- timeout value, in milliseconds
  [  --cdw2=<NUM>, -2 <NUM> ]           --- command dword 2 value
  [  --cdw3=<NUM>, -3 <NUM> ]           --- command dword 3 value
  [  --cdw10=<NUM>, -4 <NUM> ]          --- command dword 10 value
  [  --cdw11=<NUM>, -5 <NUM> ]          --- command dword 11 value
  [  --cdw12=<NUM>, -6 <NUM> ]          --- command dword 12 value
  [  --cdw13=<NUM>, -7 <NUM> ]          --- command dword 13 value
  [  --cdw14=<NUM>, -8 <NUM> ]          --- command dword 14 value
  [  --cdw15=<NUM>, -9 <NUM> ]          --- command dword 15 value
  [  --input-file=<FILE>, -i <FILE> ]   --- write/send file (default stdin)
  [  --raw-binary, -b ]                 --- dump output in binary format
  [  --show-command, -s ]               --- print command before sending
  [  --dry-run, -d ]                    --- show command instead of sending
  [  --read, -r ]                       --- set dataflow direction to receive
  [  --write, -w ]                      --- set dataflow direction to send
```

IOCTL passthru 명령을 활용하여 위의 read 명령을 재현해보면 아래와 같다.

Read command 에서 lba 영역은 cdb10, cdb11 에 걸쳐 있기 때문에 cdb10 의 값을 10으로 설정하여 lba 10 의 데이터를 읽어올 수 있다. 

```bash
$ sudo nvme io-passthru /dev/nvme0n1 --opcode=2 --date-len=512 -r -b --cdw10=10 --show-command
opcode       : 02
flags        : 00
rsvd1        : 0000
nsid         : 00000000
cdw2         : 00000000
cdw3         : 00000000
data_len     : 00000200
metadata_len : 00000000
addr         : 1124000
metadata     : 0
cdw10        : 0000000a
cdw11        : 00000000
cdw12        : 00000000
cdw13        : 00000000
cdw14        : 00000000
cdw15        : 00000000
timeout_ms   : 00000000
write new data!
```
