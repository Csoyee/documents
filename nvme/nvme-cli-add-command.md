# Add Command to existing built in 
- [reference](https://github.com/Csoyee/nvme-cli#add-command-to-existing-built-in)
- [참조 코드](https://github.com/Csoyee/nvme-cli/commit/7c3624f593eb6616996320aa8b953e19ab9471f7)

### 1. Define a new command entry in the command list
#### (1) Define a new command entry in the command list
Command list 는 `nvme-builtin.h` 에 정의되어 있다. `nvme-builtin.h` 를 보면 COMMAND_LIST 에 많은 builtin function 들이 정의되어 있다. 이 리스트에  새로운 __ENTRY__ 를 추가하자.

__ENTRY__ 는 3개의 argument 를 가진다.
- (1) "name" of subcommand : command 를 수행할 때 command line 에 입력할 이름
- (2) 해당 명령의 역할에 대한 짧은 설명문 
- (3) function callback. 
- 4번 째 인자로 alias name 을 추가할 수 있다.


#### (2) Implement callback function
__ENTRY__ 가 정의되면 callback 함수를 구현해야한다. callback 함수는 4개의 argument를 받는다: argc, argv, callback 함수에 맞는 command structure, plug-in structure.  

함수의 프로토 타입은 아래와 같다: 
```bash
int f(int argc, char ** argv, struct command *cmf, struct plugin * plugin);
```

argc와 argv 는 command line argument 로 받을 수 있다. 예를 들어서 `nvme foo --option=bar` 이라는 command 가 들어오면 argc는 1이고 argv는 "--option" 에서 시작한다.


#### (3) Define argument parsing 

