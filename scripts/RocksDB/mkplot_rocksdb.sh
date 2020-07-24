#!/bin/sh

# author: csoyee
# make WAF / ops graph 

if [ $# -lt 3 ]
then
	echo "Usage: $0 [waf log] [ops log: YCSB LOG FILE] [# of instance]"
	exit 1
fi

instance=$3

gnuplot << EOF

set terminal png size 1000, 570 enhanced font "Helvetical, 15"
set output './figure.png'

set key left top
set xlabel "Time (sec)"
set ylabel "WAF"

set ytics nomirror

set y2tics
set y2label "OPS"

set style line 1 linewidth 3 pointtype 1 pointsize 10 lc rgb "blue"
set style line 2 linewidth 3 pointtype 1 pointsize 10 lc rgb "red"
set style line 3 linewidth 3 pointtype 1 pointsize 10 lc rgb "purple"
set style line 4 linewidth 3 pointtype 1 pointsize 10 lc rgb "pink"
set style line 5 linewidth 3 pointtype 1 pointsize 10 lc rgb "cyan" 
set style line 6 linewidth 3 pointtype 1 pointsize 10 lc rgb "violet"
set style line 7 linewidth 3 pointtype 1 pointsize 10 lc rgb "orange" 
set style line 8 linewidth 3 pointtype 1 pointsize 10 lc rgb "black"


plot \
     "$1" using (\$1):(\$2) title "WAF" with lines linestyle 2,\
	"$2" using (\$3):(\$7*${instance}) smooth bezier title "OPS" with lines linestyle 5 axes x1y2,\
