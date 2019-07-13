# Running YCSB on redis
[Reference](https://github.com/brianfrankcooper/YCSB/tree/master/redis)


## YCSB 다운로드 및 compile
[참고](https://github.com/Csoyee/documents/blob/master/Workload/YCSB_How_To_Start.md)

    $ git clone https://github.com/brianfrankcooper/YCSB
    $ cd YCSB
    $ mvn -pl com.yahoo.ycsb:redis-binding -am clean package
    
    
## 데이터 로딩 및 run 
 
- Load  
    $ ./bin/ycsb load redis -s -P workloads/workloada -p "redis.host=127.0.0.1" -p "redis.port=6379"
- Run   
    $ ./bin/ycsb load redis -s -P workloads/workloada -p "redis.host=127.0.0.1" -p "redis.port=6379"      

> - redis port 번호 확인 방법: sudo systemctl status redis  
> - "-p" option을 통해 parameter을 지정해줄 수 있다. 매번 parameter 지정해주는 것이 귀찮다면 workload 파일에 작성해도 된다.
