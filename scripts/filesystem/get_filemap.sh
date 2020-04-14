#!/bin/bash


## author:: Csoyee 
## check LBA map of each file in the directory ($1)
## LBA group 확인

if [ $# -lt 1 ]
then
	echo "Usage: $0 [directory name]"
	exit 1	
fi

search_dir=$1

for entry in `ls $search_dir`; do
#	if [[ $entry == *".sst" ]];
#	then
		sudo hdparm --fibmap $search_dir/$entry
#	fi
done
