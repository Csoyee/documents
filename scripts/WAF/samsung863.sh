#!/bin/bash


if [ $# -lt 1 ]
then
	echo "Usage $0 [inputfilename]"
	exit 1
fi

INPUT_FILE=$1

cat $INPUT_FILE | grep "^241" | awk '{print $10*512}' >  LBA_$INPUT_FILE
cat $INPUT_FILE | grep "^251" | awk '{print $10*512}' >  SSD_$INPUT_FILE

First_LBA=$(head -n 1 LBA_${INPUT_FILE})
First_SSD=$(head -n 1 SSD_${INPUT_FILE})

echo $First_LBA
echo $First_SSD

bef_lba=$First_LBA
bef_ssd=$First_SSD

count=0

rm cum_$INPUT_FILE
rm run_$INPUT_FILE
rm w_$INPUT_FILE
rm l_$INPUT_FILE
while true
do
	read -r lba <&3 || break
	read -r ssd <&4 || break

	if [ $(($lba-$First_LBA)) -ne 0 ]
	then
		echo -n "$((($count-1)*300)) ">> cum_$INPUT_FILE
		echo "scale=3; (($ssd-$First_SSD) / ($lba-$First_LBA))" | bc >> cum_$INPUT_FILE
		echo -n "$((($count-1)*300)) ">> w_$INPUT_FILE
		echo "(($ssd-$First_SSD))" | bc >> w_$INPUT_FILE
		echo -n "$((($count-1)*300)) ">> l_$INPUT_FILE
		echo "(($lba-$First_LBA))" | bc >> l_$INPUT_FILE
	fi

	if [ $(($lba-$bef_lba)) -ne 0 ]
	then
		if (( (($count%1)) == 0 ))
		then
			echo -n "$((($count-1)*300)) " >> run_$INPUT_FILE
			echo "scale=3; (($ssd-$bef_ssd) / ($lba-$bef_lba))" | bc >> run_$INPUT_FILE
			bef_lba=$lba
			bef_ssd=$ssd
		fi
	fi


	count=$(($count+1))
done 3< LBA_$INPUT_FILE 4<SSD_$INPUT_FILE

rm w_$INPUT_FILE
rm l_$INPUT_FILE
rm LBA_$INPUT_FILE
rm SSD_$INPUT_FILE
