#!/bin/sh

if [ $# -lt 2 ] 
then
	echo "Usage: $0 [device name] [filename ]"
	exit 1
fi

DEV_NAME=$1
FILE_NAME=$2

gnuplot <<EOF

set terminal png size 1000,570 enhanced font "Helvetical, 13"

set output './iostat.png'

set grid

set xrange[0:2000]
set key out horiz bot center
set xlabel "Time (sec)"
set ylabel "util (%)"
set yrange[0:100]

set y2label "Bandwidth"


set style line 1 linewidth 3 pointtype 1 pointsize 10 lc rgb "blue"
set style line 2 linewidth 3 pointtype 1 pointsize 10 lc rgb "red"
set style line 3 linewidth 3 pointtype 1 pointsize 10 lc rgb "purple"
set style line 4 linewidth 3 pointtype 1 pointsize 10 lc rgb "pink"
set style line 5 linewidth 3 pointtype 1 pointsize 10 lc rgb "green"
set style line 6 linewidth 3 pointtype 1 pointsize 10 lc rgb "cyan"

plot  "< grep ${DEV_NAME} ${FILE_NAME}" using 0:16  smooth bezier title "IO util" with lines linestyle 1 ,\
	"< grep ${DEV_NAME} ${FILE_NAME}" using 0:5  smooth bezier title "Write Bandwidth" with lines linestyle 2 axes x1y2,\
	"< grep ${DEV_NAME} ${FILE_NAME}" using 0:4  smooth bezier title "Read Bandwitdh" with lines linestyle 3 axes x1y2,\

