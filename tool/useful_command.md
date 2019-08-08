# Useful commands
유용한 command 정리


## Make dump file
- x bytes 만큼의 file size 를 맞는 file "A.txt" 만들기
```bash
$ fallocate -l x A.txt

# x bytes 대신 y GB 사이즈의 파일을 만들고 싶은 경우
$ fallocate -l yG A.txt
```

## paste
```bash
# example file content
#### fileA.txt
# 1 2
# 3 4
# 5 6
####
#### fileB.txt
# 7 8
# 9 10
# 11 12
####

$ paste fileA.txt fileB.txt

# result 
####
# 1 2 7 8
# 3 4 9 10
# 5 6 11 12
####
```

## Cut string 
- delimeter "a" 를 기준으로 n 번 째 단어를 출력하라  
```bash
# delimeter must be a single character
$ cut -f n -d "a"

# Example (is 와 example 사이에 space 2개 있음.)
$ echo "This is  example" | cut -f 1 -d " "
> This
$ echo "This is  example" | cut -f 2 -d " "
> is
$ echo "This is  example" | cut -f 3 -d " "
>  
$ echo "This is  example" | cut -f 4 -d " "
> example
```

## awk
```bash
# sample_file의 첫 번째 인자 합계 계산 (default delimeter 은 공백)
$> cat "sample_file" | awk '{sum += $1} END {print sum}'

# 평균 계산
$> cat "sample_file" | awk '{sum += $1 ; count += 1} END {print sum/count}'

# delimeter 사용 (예시 .)
$> cat "sample_file" | awk -F "." '{sum+=$1} END {print sum}'
```

## sort 
[참고링크](https://linuxmadang.tistory.com/entry/linux%EB%A6%AC%EB%88%85%EC%8A%A4-sort-%EB%AA%85%EB%A0%B9%EC%96%B4)
```bash
$> cat "sample_file" | sort

# 정렬 + 중복 제거 + 중복 개수 count
$> cat "sample_file" | sort | uniq -c

# Example: 특정 파일(sample_file)의 delimeter " " 기준 n번째 인자를 소팅하고 중복을 제거한다.
$> cat "sample_file" | awk -F " " '{print ${num}}' | sort | uniq -c
```
