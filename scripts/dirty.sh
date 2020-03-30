#/bin/bash

## reference : https://blog.helperchoi.com/120
## add by : Csoyee
## write back 등 정보 추가 

KERNEL_MAJOR_CHECK=`uname -r | cut -d "-" -f 1 | cut -d "." -f 1`
KERNEL_MINOR_CHECK=`uname -r | cut -d "-" -f 1 | cut -d "." -f 3`

declare -a ARRAY_TIME
declare -a ARRAY_MEMLIST
ARRAY_TIME=("${ARRAY_TIME[@]}" "`date "+%d %T"`")

for MEM_LIST in `cat /proc/meminfo | awk '{print $2}'`
do
	ARRAY_MEMLIST=("${ARRAY_MEMLIST[@]}" "`echo ${MEM_LIST}`")
done
DIRTY_FLUSH_RATIO=`cat /proc/sys/vm/dirty_background_ratio`
DIRTY_CRITICAL_RATIO=`cat /proc/sys/vm/dirty_ratio`
DIRTY_CRITICAL_LIMIT=`echo "$DIRTY_CRITICAL_RATIO - 5" | bc`
CPU_CORE=`cat /proc/cpuinfo | grep -i process | wc -l`
LOAD_AVERAGE=`cat /proc/loadavg | awk '{print $1}'`
LOAD_AVERAGE_LIMIT=`echo "scale=3; ${CPU_CORE} * 2.5" | bc`
RF_USAGE=`df -hP | awk '$6 ~ /\/$/ {print $5}'`
MEM_TSIZE=${ARRAY_MEMLIST[0]}
MEM_FSIZE=${ARRAY_MEMLIST[1]}

CACHE_SIZE=${ARRAY_MEMLIST[4]}
SWAP_SIZE=${ARRAY_MEMLIST[14]} 
SWAP_FREE=${ARRAY_MEMLIST[15]}
DIRTY_SIZE=${ARRAY_MEMLIST[16]} 
WRITEBACK_SIZE=${ARRAY_MEMLIST[17]} 

FILE_ACTIVE=${ARRAY_MEMLIST[10]}
FILE_INACTIVE=${ARRAY_MEMLIST[11]}

PDFLUSH_THREAD=`ps -ef | grep -v grep | grep kworker | wc -l`

MEM_USIZE=`echo "((${MEM_TSIZE} - ${MEM_FSIZE} - ${CACHE_SIZE}) * 100) / ${MEM_TSIZE}" | bc`
SWAP_USE=`echo "${SWAP_SIZE} - ${SWAP_FREE}" | bc`
EXPR1=`echo "${DIRTY_SIZE} * 100" | bc`
EXPR2=`echo "scale=2; ${EXPR1} / ${CACHE_SIZE}" | bc`
RUN_PROC=`ps -ef | wc -l`
RUN_THREAD=`ps -eL | wc -l`

#echo "$(date "+%d %T") [ Real Memory Usage ] : ${MEM_USIZE} %"
echo "$(date "+%d %T") [Root Filesystem Usage] : ${RF_USAGE}"
echo "$(date "+%d %T") [Total Memory] : ${MEM_TSIZE} KB"
echo "$(date "+%d %T") [Free Memory] : ${MEM_FSIZE} KB"
echo "$(date "+%d %T") [Page Cache] : ${CACHE_SIZE} KB"
echo "$(date "+%d %T") [Dirty Page] : ${DIRTY_SIZE} KB"
echo "$(date "+%d %T") [Write Back] : ${WRITEBACK_SIZE} KB"
echo "$(date "+%d %T") [INACTIVE] : ${FILE_INACTIVE} KB"
echo "$(date "+%d %T") [ACTIVE] : ${FILE_ACTIVE} KB"
#echo "$(date "+%d %T") [Disk Flush Thread] : ${PDFLUSH_THREAD}"
#echo "$(date "+%d %T") [Dirty Ratio LIMIT] : ${DIRTY_CRITICAL_RATIO}%"
echo "$(date "+%d %T") [Dirty Ratio Status] : ${EXPR2} / 100%"
echo "$(date "+%d %T") [Swap Memory Status] : ${SWAP_USE} KB / ${SWAP_SIZE} KB"
#echo "$(date "+%d %T") [Process Total Count] : ${RUN_PROC}"
#echo "$(date "+%d %T") [Thread Total Count] : ${RUN_THREAD}"
#echo "$(date "+%d %T") [System Loadaverage] : ${LOAD_AVERAGE} (${CPU_CORE} Core System)"

