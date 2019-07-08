# Getting Started 
[Reference](https://github.com/brianfrankcooper/YCSB)

## Prerequisite
- YCSB는 Maven3 version을 필요로 함. (Maven2를 사용할 경우 [다음](https://github.com/brianfrankcooper/YCSB/issues/406)과 같은 에러 발생)
    > [maven3 설치](http://anddev.tistory.com/104)
- 자바 버전 8 
    > [자바 8 설치](https://zetawiki.com/wiki/%EC%9A%B0%EB%B6%84%ED%88%AC_Java_8_%EC%84%A4%EC%B9%98)

## Download
    $ git clone https://github.com/brianfrankcooper/YCSB
    
## Compile
- 각각의 데이터베이스 바인딩 디렉토리 아래에 README 파일에 컴파일 방법이 명시되어 있음  
e.g., Redis compile  
    $ mvn -pl com.yahoo.ycsb:redis-binding -am clean package

## Run
- loading
    $ bin/ycsb.sh load (dbname) -P (workload name)
- run 
    $ bin/ycsb.sh run (dbname) -P (workload name)
