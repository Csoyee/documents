# py-tpcc

py-tpcc 는 파이썬 베이스의 TPC-C 벤치마크로 해당 [링크](https://github.com/apavlo/py-tpcc)에 소스코드가 있다.

나의 경우 SQLite 상에서 tpcc 를 수행하였다. 

## Get started

** python base 이기 때문에 당연히 python 이 깔려있어야 한다. (sudo apt-get install python)
** sqlite 를 사용할 것이기 때문에 sqlite 를 build, install 해야한다.

### Download Source Code
[py-tpcc 깃헙](https://github.com/apavlo/py-tpcc) 에서 소스코드를 다운받는다.

```bash
$ git clone https://github.com/apavlo/py-tpcc
$ cd py-tpcc/pytpcc/
```

### Configure and Run

pytpcc 디렉토리에있는 pytpcc.py 파이썬 프로그램을 통해 tpcc 를 수행할 수 있다. 

(1) Configure

```bash
$ python ./tpcc.py --print-config sqlite > sqlite.config
```

위의 command 를 사용하면 sqlite.config 파일에서 아래와 같은 내용을 확인할 수 있다.
```bash
# SqliteDriver Configuration File
# Created 2019-11-01 11:42:57.601103
sqlite]

# The path to the SQLite database
database             = /tmp/tpcc.db
```

이는 config 파일로 추후 다른 configuration 을 추가할 수 있다. config 파일 말고도 cli 를 통해서도 configuration 을 할 수 있다. 
세부 configuration 은 [아래](#Configuration)에서 확인하자

(2) Load and Run
```bash
## LOAD
$ python ./tpcc.py --no-execute --config=sqlite.config

## RUN
$ python ./tpcc.py --no-load --config=sqlite.config
Execution Results after 60 seconds
------------------------------------------------------------------
                  Executed        Time (µs)       Rate            
  DELIVERY        22              5964317.79861   3.69 txn/s      
  NEW_ORDER       195             33582508.3256   5.81 txn/s      
  ORDER_STATUS    15              5158.66279602   2907.73 txn/s   
  PAYMENT         206             20382380.2471   10.11 txn/s     
  STOCK_LEVEL     22              55040.5979156   399.70 txn/s    
------------------------------------------------------------------
  TOTAL           460             59989405.632    7.67 txn/s      
```


### Configuration
python 의 argparse 패키지를 임포트해서 argument 파싱하는 코드를 메인 함수의 맨 앞에 넣음.

- `--config`       : configuration file path (no default value)
- `--reset`        : 드라이버에게 database 의 내부를 reset 하도록 지시함 (default: true)
- `--warehouses`   : warehouse 개수 (default: 4)
- `--duration`     : benchmark 수행 시간 (단위: 초) (default: 60)
- `--clients`      : client 개수 (default: 1)
- `--stop-on-error`: exception 발생했을 때 transaction 을 멈춤 (default: true)
- `--no-load`      : loading 수행하지 않음 (이미 로딩해놓고 run 만하는 경우에 사용함, default: true)
- `--no-execute`   : loading 만 수행함 (default: true)
- `--scalefactor`  : default 갑은 1 이다.
