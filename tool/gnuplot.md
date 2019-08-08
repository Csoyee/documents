# Gnuplot


## Install
- To be updated ...

## Before start
Install 과정이 원활하게 진행되어 /use/bin/gnuplot 에 제대로 gnuplot 이 설치되었음을 가정함.

- shell script 에서는 해석기가 bash 쉘이기 때문에 해석할 프로그램의 위치인 /bin/bash 를 명시한다. `#!/bin/bash` 
- gnuplot 의 해석기로는 gnuplot 이 설치된 위치를 명시한다. `#!/usr/bin/gnuplot`

## 주요 Command 정리 
### 1. 포맷 정하기 (png / eps)
```bash
# png file
> set terminal png 

# eps file
> set terminal post
```  
- 이 때 이미지 사이즈 및 전체 그래프의 폰트도 같이 지정할 수 있다.
```bash
# png file
> set terminal png size 1000, 570 enhanced font "Helvetical, 13"

# eps file
> set terminal post size 1000, 570 enhanced font "Helvetical, 13"
```

### 2. 결과 파일 이름 정하기
```bash
> set output 'Output.eps'
```

### 3. 범례
- 기본적으로 set key 명령을 통해서 수행된다.
```bash
#### position 정하기
# 그래프 내 왼쪽 아래
> set key left bottom
# 그래프 내 우측 위
> set key right top 

### 그래프 외부
# 그래프 아래 센터
> set key out bot center 
# 그래프 오른쪽 아래
> set key out bot right

#### 범례의 정렬: 범례가 3개 있을 때 가로로 정렬할지 세로로 정렬할지 (그래프 내 오른쪽 위로 가정)
# 가로 정렬 
> set key vert right top
# 세로 정렬
> set key horiz right top
```

### 4. 축 이름 정하기
```bash
# x 축
> set xlabel "x축"
# y 축
> set ylabel "y축"
```

### 5. 인풋 파일에 따라서 plotting 하기
- 인풋 파일 포멧은 아래와 같다.
```bash
# input file name "input.txt"
0 1
1 2
2 1
```
- 1열을 x축으로 2열을 y축으로 갖는 plot 을 만들기 위해서는 아래와 같이 작성한다.
```bash
# plot "인풋_파일_이름" using "[x축으로 쓸 열]:[y축으로 쓸 열]" title "해당 데이터의 이름" with lines
> plot "input.txt" using 1:2 title "data1" with lines 
```
- 이 때 1열 대신 그냥 인풋 파일의 행 번호를 x축으로 쓰고 싶다면 아래와 같이 작성한다.
```bash
> plot "input.txt" using 0:2 title "data1" with lines 
```
- 여러 인풋 파일 input1.txt, input2.txt 의 데이터를 한 그래프에 표현하고 싶다면 아래와 같이 작성한다. (인풋 포멧은 위의 나온 것과 같다고 가정한다.)
```bash
> plot "input1.txt" using 1:2 title "data1" with lines ,\
  plot "input2.txt" using 1:2 title "data2" with lines
```

### 6. 기타 등_등 (to be added...)  
#### 6-1. 라인 스타일 설정하기  
- set linestyle

#### 6-2. 추세선 그리기  
- smooth bezier 

#### 6-3. 2개의 y축을 갖는 그래프 그리기  
- y2tics를 설정한 다음 기존에 y축 관련하여 사용했던 명령과 같이 사용하되 y 대신 y2 라고 명명한다.
```bash
> set y2tics
> set y2label "y축2"
```
- plotting 을 할 때는 comma (,) 를 기준으로 두 개의 데이터를 같이 넣어준 뒤 axes 를 통해 어떤 y축을 의미하는지 명명한다.
```bash
> plot "input1.txt" using 1:2 title "data1" with lines axes x1y1, "input2.txt" using 1:2 title "data2" with lines axes x1y2
```
#### 6-4. frequency graph 그리기  
- smooth frequency

#### 6-5. x축 시간 데이터 넣기
```bash
# xdata 로 시간 데이터를 쓸 것 임을 명시
> set xdata time
# 사용할 시간 포맷을 명시 -- [Y:년/m:월/d:일/H:시/M:분/S:초]
> set timefmt '%Y/%m/%d-%H:%M:%S'
```

#### 6-6. 서로 다른 열에 대한 연산 결과를 결과 데이터로 넣기
__동일 파일__  
(e.g..)
fileA.txt   
> 2 4  
> 3 2  
> 1 1  

```bash
plot "fileA.txt" using 0:($1+$2) title "SUM" with lines,\
  "fileA.txt" using 0:($1+$2)/2 title "AVG" with lines
```


__서로 다른 파일의 열을 합할 때__  
(e.g..)  
fileA.txt     
> 1 4  
> 2 2  
> 3 1  
fileB.txt
> 1 2  
> 2 3  
> 3 1  

```bash
> plot "< paste fileA.txt fileB.txt" using 0:($2+$4) title "SUM" with lines,\
>  "< paste fileA.txt fileB.txt" using 0:($2+$4)/2 title "AVG" with lines
```
