# YCSB-TS


YCSB-TS 는 [YCSB](https://github.com/brianfrankcooper/YCSB)로부터 클론되어 time domain function 및 timestamp / timerange 등을 지원하도록 수정되었다. 
지원 가능한 데이터베이스 목록은 [다음](http://tsdbbench.github.io/Overlord/#supported-databases)과 같다.

## YCSB-TS for MySQL   
[소스코드](https://github.com/TSDBBench/YCSB-TS/blob/master/jdbc/src/main/java/com/yahoo/ycsb/db/JdbcDBClient.java)

### How to setup?
- To be added ...

### Operations
- 크게 3개의 operation(read/insert/scan)으로 구성됨 (각각의 operation은 소스코드 상에서 read/insert/scan 이라는 함수로 구현되어있다.)

#### READ
- createAndCacheReadStatment 함수에서 아래와 같은 query를 생성하는 것을 알 수 있음.
```bash
StringBuilder read = new StringBuilder("SELECT * FROM ");
read.append(readType.tableName);
read.append(" WHERE ");
generateTagString(tags, read);
read.append(" ( ");
read.append(TIMESTAMP_KEY);
read.append(" = ");
read.append("?);");
```
- readType.tableName 은 이미 세팅되어있고 TIMESTAMP_KEY는 YCSB_KEY 로 정의되어 있다.  
- 따라서 이 결과 만들어지는 쿼리는 아래와 같다.    
    ```bash
    # (특정 Timestamp key 를 갖는 테이블의 값을 select하는 쿼리)
    $> SELECT * FROM [tableName] WHERE (YCSB_KEY=?);  `
    ```
    
#### SCAN
- aggregation 함수를 활용해서 select 한 결과를 가공한다. 
- 크게 3가지로 aggregation operation을 수행한다. (avg/count/sum) 따라서 인자로 넘어온 값에 따라 select string 을 결정한다.
```bash
StringBuilder select = new StringBuilder("SELECT " + selectStr + " FROM ");
select.append(scanType.tableName);
select.append(" WHERE ");
generateTagString(tags, select);
select.append(TIMESTAMP_KEY);
select.append(" BETWEEN ? AND ? ");
select.append(groupByStr + ";");
```
- 위에서 selectStr 은 avg/count/sum 여부에 따라서 예를 들어 avg 인 경우 `AVG(VALUE) AS VALUE` 로 결정되어 있으며, groupByStr 도 필요한 경우 `GROUP BY TEIMSTAM_KEY` 로 설정되어있다. 


#### INSERT
- insert 의 경우 따로 특별하게 사용되는 인자는 없으며 field 개수에 따라서 데이터를 여러 개 insert 한다.
```bash
StringBuilder insert = new StringBuilder("INSERT INTO ");
insert.append(insertType.tableName);
insert.append(Columns);
insert.append(" VALUES(?");
for (int i = 1; i < insertType.numFields; i++) {
    insert.append(",?");
}
insert.append(");");
```
