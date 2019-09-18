# SQLite Internals 정리

Copyright. 2006 by Michael Owens



## Overview 
### Architecture
SQLite 는 아래의 그림과 같이 8개의 분리된 모듈로 구성되어 있으며 이러한 모듈들은 크게 3개의 주요한 subsystem (Compiler, Core, Backend) 으로 그룹화 될 수 있다.
상위 모듈들은 query 를 컴파일하고 중간 모듈에서는 이렇게 컴파일한 query를 수행한다. 그리고 하위 모듈들은 OS 와 interfacing 하고 storage 처리하는 것을 담당한다.

![image](https://user-images.githubusercontent.com/18457707/65115030-603f1180-da22-11e9-8b6b-2c81f26b9f5d.png)

#### Interface
- 인터페이스는 스택의 상위에 위치하며 SQLite의 C API로 이루어져있으며 말 그대로 SQLite의 사용자가 SQLite 와 대화할 수 있는 곳이다. 

#### Compiler
- 컴파일 과정은 `tokenizer` 과 `parser` 로 시작한다. 이 들은 텍스트 포멧의 SQL 구문을 받고; 문법(syntax) 검사를 하고; 하위의 레이어에서 쉽게 사용할 수 있는 데이터 스트럭쳐로 변환하는; 작업을 수행한다. `Tokenizer` 에서 구문을 분리하고 이렇게 분리된 토큰들을 `Parser` 에서 의미를 부여하여 `code generator` 로 보낸다. 

- `Code generator 은 parse tree 를 SQLite 를 위한 assembly 언어와 같은 형태로 해석한다. 이러한 assembly 언어는 `virtual machine` 을 통해 수행 가능한 instructions 들로 이루어져 있다. 

#### Virtual Machine
- stack 의 중심에는 `Virtual machine (= *VDBE, virtual database engine*)` 이 있다. `VDBE` 는 바이트 코드로 수행되는 가상 머신으로 OS, CPU 혹은 하위 시스템 구조에 독립적이다. 
- `VDBE`는 데이터 처리를 위해서 디자인 되었으며  모든 instruction set 에 있는 instruction 들은 특정 데이터베이스 작업을  의미한다. 

#### Back End
- back end 는 `B-tree`, `page-cache` 그리고 `OS interface` 로 구성된다. `B-tree`와 `page cache(pager)` 은 같이 수행된다. 그들은 데이터베이스 페이지를 매개로 소통하며 데이터베이스 페이지 내부에는 *records, columns, index entries* 등에 대한 정보가 있다. `B-tree` 와 `pager` 모두 데이터베이스 페이지에 쓰여있는 내용에 대해서는 아는 바가 없고(알 필요도 없다) 오직 해당 페이지를 옮기거나 위치시키는 역할을 한다.

- `B-tree` 의 역할은 order 이다. `B-tree` 는 페이지 사이의 모든 페이지들을 연결하고 쉽게 위치시킬 수 있는 페이지 간의 복잡한 관계 정보를 관리한다. 전체적인 구조는 트리 형태의 구조를 띄고 있으며 searching 을 위해서 최적화 되어있다. 
- `Pager` 은 `B-tree` 에 페이지를 제공하는 역할을 한다. 효과적으로 페이지를 제공하는 것이 `pager` 의 역할이다. 디스크 opertation 들은 SSD가 등장했음에도 불구하고 여전히 느린 작업이기 때문에 `pager`은 자주 쓰이는 페이지들은 메모리 캐싱함으로써 disk 에의 접근을 줄이고자 한다. 이를 위해서 어던 페이지가 추후에 사용될지 예측할 수 있는 기술이 필요하다. 또한 `pager` 은 트랜잭션 관리, 데이터베이스 locking, 그리고 crash recovery 를 담당한다. 관련된 대부분의 작업들은 OS interface 를 거치게 된다.

- file locking 과 같은 작업들은 OS 시스템마다 다르게 구현되어 있기 때문에 `OS interface`는 이러한 시스템의 차이를 SQLite 의 다른 모듈에서 알 수 없도록 하는 역할을 한다. 즉 `pager` 에서는 file locking 을 수행할 때 어떤 OS 상에서 수행되고 있는가를 고려할 필요가 없다는 것이다. 

#### Utilities and Test Code


## SQLite Internals and New Features

### The B-Tree and Pager Module

`B-tree` 는 *O(logN)* 의 lookup, insert, delete 를 제공하고 O(1) 의 양방향 record traversal 의 기능을 제공한다. 이러한 `B-tree` 는 디스크에서 데이터페이지를 어떻게 읽고 쓸지에 대해서는 고려하지 않고 오직 페이지간의 관례를 고려한다. 대신 데이터페이지가 필요하거나 데이터페이지 변경이 필요한 경우 `pager` 에 페이지가 필요함을 알린다. 페이지를 수정할 때에 _rollback journal_ 을 사용하는 경우 기존의 페이지가 저널 파일에 우선 복사되었음을 보장해야 한다. `B-tree` 는 또한 쓰기 작업이 끝았을 경우에도 `pager` 에 쓰기 작업이 끝났음을 알리고 `pager`은 트랜잭션의 state를 확인하여 어떤 작업을 수행해야하는지 결정한다.

#### Database File Format
- 데이터베이스의 모든 페이지는 1부터 순차적으로 순차적으로 번호가 매겨진다. 데이터베이슨느 여러개의 B-tree 로 구정되며 (테이블과 index 당 하나의 B-tree) 각각의 테이블 혹은 인덱스는 첫번째 페이지의 위치를 정의하는 root page 를 가지고 있다. `sqlite_master` 테이블에 모든 root page 정보다 저장된다. 
- 데이터베이스의 첫 번째 페이지 (Page 1) 는 특별하다. Page1 의 처음 100 바이트는 100B 의 file header 을 가지고 있으며 file header 에는 데이터베이스 파일에 대한 정보(e.g., 라이브러리 버전, 스키마 버전, 페이지 사이즈 ... )가 들어있다. 또한 page1 은 `sqlite_master` 테이블의 root page를 담당한다.

#### B-Tree Records (payloads)
- `B-Tree` 의 페이지는 `payload` 라고 불리는 b-tree 레코드로 구정되어 있다. b-tree 레코드는 table 의 column 과 같은 데이터베이스 레코드와 다르다. 
- `Payload` 는 오직 두개의 field 를 가진다 - key field; data field. Key field 는 _rowid_ 값 혹은 _primary key_ 값을 가진다. Data field 는 어떤 값이든 가질 수 있다. 결국 데이터베이스 레코드는 data field 에 저장되게 된다. 
- `Payload` 의 크기는 다양하며 일반적으로 각각의 페이지는 여러개의 `payload` 를 가지고 있다. (예외적으로 `payload` 가 너무 큰 경우에는 하나의 `payload` 가 여러개의 페이지에 걸쳐서 위치하기도 한다.)

#### B+tree 
- B-tree 레코드는 key 순서에 따라서 저장된다. 모든 key는 단일 B-tree 내에서 unique 한 값을 가져야 한다. (이는 rowid, primary key 가 key field 로 사용되기 때문에 자동으로 만족된다.) 
![image](https://user-images.githubusercontent.com/18457707/65122428-e9a71180-da2b-11e9-9f38-9d926b3018ca.png)
- Root page와 Internal Page 는 모두 navigation 을 위한 페이지로 data 들은 아래 level 페이지에 대한 pointer을 의미한다. 모든 database record 는 leaf page 에 저장되어 있다. Leaf level 에 레코드와 페이지는 key 순서대로 위치하기 때문에 B-tree cursor 이 leaf page 하나만 제공되었을 때 양방향으로 traversing 할 수 있다. 

#### Records and Fields

- leaf page 의 data field 에 있는 데이터베이스 레코드는 VDBE 에 의해서 관리된다. 레코드는 헤더, 데이터 순서의 바이트 형식으로 이루어져있다.
- Header segment: 헤더 사이즈와 데이터 세그먼트에 저장된 데이터의 각각의 필드에 대한 데이터타입을 의미하는 타입 정보로 이루어져있다. 

![image](https://user-images.githubusercontent.com/18457707/65122984-393a0d00-da2d-11e9-89b1-e36b44d00bb5.png)

헤더에 데이터 타입을 명시하기 위해서 각각의 Field Type Value 들이 정의 되어 있으며 대표적으로 integer type인 경우 type value로 1~4의 값, text type 인 경우 type value로 N>13 의 홀수 값을 갖는다 (text type 의 경우 data의 length 가 (N-13)/2). 

따라서 아래의 케이스가 있다고 가정했을 때:
```bash
$ sqlite> SELECT * FROM episodes ORDER BY id LIMIT 1;
id  season  name
--- ------- -------------------
0   1       Good News Bad News
```

내부의 record format 은 아래와 같다.

| 04 | 01 | 01 | 49 | 00 | 01 | Good News Bad News |

헤더는 4byte 길이이며 id와 season 는 1-byte signed integer 이어서 type value로 01을 갖고, name 은 길이에 맞추어 (49-13)/2 = 18 , type 값으로 49 를 갖는다. 

#### Hierarchical Data Organization
![image](https://user-images.githubusercontent.com/18457707/65123558-7b178300-da2e-11e9-9efb-cdad6e9250e1.png)




