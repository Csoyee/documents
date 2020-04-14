#!/bin/bash

rm ~/ssd/testfile.0.0

sync


fio --directory=/home/csoyee/ssd --name=testfile --direct=1 --ioengine=psync --iodepth=1 --rw=randwrite --bs=4K --filesize=1G

sync

sleep 5

gcc -o discard  discard.c

time sudo ./discard 4096
#time sudo ./discard 67108864
