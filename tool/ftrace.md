# 1. Ftrace가 무엇인지?
 - 커널 내부에서 함수 콜을 추적할 수 있는 트레이싱 유틸리티
 - 이점   : 커널 내부에서 어떤 일이 일어나고 있는지를 알 수 있음
 - 사용 예 : 디버깅 툴로, latency 추적이나 시스템 분석을 위해서 사용할 수 있다.

# 2. Ftrace 세팅하기
 - interface with Ftrace: Debugfs 파일시스템에 위치.
 - `/sys/kernel/debug` 에 마운트 되어있음.

 - 디버깅 목적에 따라서 아래 설정 파라미터를 enable 시켜야 함
    > CONFIG_FUNCTION_TRACER  
    > CONFIG_FUNCTION_GRAPH_TRACER  
    > CONFIG_STACK_TRACER  
    > CONFIG_DYNAMIC_FTRACE


# 3. 함수 트레이싱

## 3-1) control files
- current_tracer: 현재 설정된 트레이서를 세팅하거나 보여줌
- available_tracers: 본 파일에 리스팅된 트레이서들은 이름을 `current_tracer`에 에코하여서 설정할 수 있다.
- tracing_on: 트레이스에 쓰는 것이 활성화(enable) 되어 있는지 표시 (3-4 절 참조)
- trace: 사람이 읽을 수 있는 포맷의 트레이스 결과를 가지고 있음. (본 파일이 열려있는 동안에는 트레이싱 되지 않는다)
- set_ftrace_filter: 함수명을 echoing 해서 본 파일에 쓰면 트레이스에 본 파일에 있는 함수명만 추적
- set_ftrace_notrace: set_ftrace_filter 과 반대

## 3-2) function tracer 활성화 방법
```bash
# current_tracer 파일에 "function" 을 에코한다.
$ echo function > current_tracer
$ cat trace | head -10
#
# tracer: function
#
#           TASK-PID    CPU#    TIMESTAMP  FUNCTION
#              | |       |          |         |
            bash-16939 [000]  6075.461561: mutex_unlock <-tracing_set_tracer
```
 - header: 결과값 포멧을 결정
   - timestamp: boot 시점으로부터의 시간.  
   - function : "<-" symbol을 통해서 parent 로 부터 tracing 됨.
   	- 예시 
   	<img width="484" alt="Screen Shot 2019-07-10 at 12 28 29 AM" src="https://user-images.githubusercontent.com/18457707/60901925-bc124f00-a2a9-11e9-8e37-4809601b18eb.png">

   

## 3-3) function graph tracer enable
```bash
# function tracer enable 하는 방법과 동일하다.
$  echo function_graph > current_tracer
$  cat trace | head -20
#
# tracer: function_graph
#
# CPU  DURATION                  FUNCTION CALLS
# |     |   |                     |   |   |   |
 1)   1.015 us    |        _spin_lock_irqsave();
 1)   0.476 us    |        internal_add_timer();
 1)   0.423 us    |        wake_up_idle_cpu();
 1)   0.461 us    |        _spin_unlock_irqrestore();
 1)   4.770 us    |      }
 1)   5.725 us    |    }
```

## 3-4) enable 방법
- echo 0 > tracing_on    /* disabled */
- echo 1 > tracing_on    /* enabled  */



