# Discard

Discard(TRIM) 는 사용자가 더이상 사용하지 않는 블록들을 폐기하는 기능이다.  `fstrim` 명령을 통해 사용자에 의해 직접 폐기할 수도 있고 디바이스 마운트 시에 `-o discard` 옵션을 주면 온라인으로 파일 시스템에서 수행한다.


## Discard 옵션

1. 마운트 시 discard 옵션을 준다.
```bash
$ sudo mount -o discard /dev/[devname] [mount path]
```
2. /etc/fstab 파일 변경 
  - `/etc/fstab` 은 파일시스템테이블을 의미한다. 파일시스템의 정보를 정적으로 가지고 있다. 
  - 첫 번째 열은 디바이스 이름, 두 번째 열은 마운트 포인트 , 세 번째 열은 파일시스템 이름, 네 번째 열은 옵션 등등 ...
  - 네 번째 열 옵션에 discard 를 추가해준다. 


## Discard 옵션 사용 가능 여부 확인 
```bash
$ lsblk -D
```
위의 명령을 수행하면 아래와 같은 결과를 얻을 수 있다. 이 때 DISC-MAX 가 0이 아니면 TRIM이 사용가능함을 의미한다.   
  ![image](https://user-images.githubusercontent.com/18457707/61609468-328f5380-ac91-11e9-8b94-896edd5b6cf4.png)


## Discard 옵션 활성화 테스트
1. 임의의 테스트 파일 `trimTest.txt` 하나 생성하고 데이터를 채운다.
2. `$ sudo hdparm --fibmap trimTest.txt` 명령을 통해 새롭게 만든 파일의 start lba를 확인한다. (start lba를 12345 라고 하자)
3. `$ sudo hdparm --read-sector 12345 /dev/[devname]` 명령을 치면 파일 영역에 데이터가 써져있음을 알 수 있다.
4. `$ rm trimTest.txt` 명령을 통해 파일을 delete 한다
5. `$ sync`
6. `$ sudo hdparm --read-sector 12345 /dev/[devname]` 명령(3번 명령과 동일)을 다시 입력하여 확인했을 때 이전에 채워져있던 파일 영역의 sector이 모두 0으로 바뀌어있다면 discard 옵션이 제대로 동작하는 것이다.
