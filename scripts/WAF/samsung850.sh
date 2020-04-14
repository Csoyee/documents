#!/bin/bash


if [ $# -lt 1 ]
then
	echo "Usage $0 [inputfilename]"
	exit 1
fi


echo "Assume that deivce size is 256GB."

INPUT_FILE=$1

cat $INPUT_FILE | grep Total_LBAs_Written | awk '{print $10*512}' >  LBA_$INPUT_FILE
cat $INPUT_FILE | grep Wear_Leveling_Count | awk '{print $10*256*1024*1024*1024}' >  Wear_$INPUT_FILE

First_LBA=$(head -n 1 LBA_${INPUT_FILE})
First_WEAR=$(head -n 1 Wear_${INPUT_FILE})

echo $First_LBA
echo $First_WEAR

bef_lba=$First_LBA
bef_wear=$First_WEAR

count=0

rm cum_$INPUT_FILE
rm run_$INPUT_FILE
while true
do
	read -r lba <&3 || break
	read -r wear <&4 || break

	if [ $(($lba-$First_LBA)) -ne 0 ]
	then
		echo "scale=3; (($wear-$First_WEAR) / ($lba-$First_LBA))" | bc >> cum_$INPUT_FILE
		echo "(($wear-$First_WEAR))" | bc >> w_$INPUT_FILE
		echo "(($lba-$First_LBA))" | bc >> l_$INPUT_FILE
	fi

	if [ $(($lba-$bef_lba)) -ne 0 ]
	then
		if (( (($count%10)) == 0 ))
		then
			echo "scale=3; (($wear-$bef_wear) / ($lba-$bef_lba))" | bc >> run_$INPUT_FILE
			bef_lba=$lba
			bef_wear=$wear
		fi
	fi


	count=$(($count+1))
done 3< LBA_$INPUT_FILE 4<Wear_$INPUT_FILE


rm w_$INPUT_FILE
rm l_$INPUT_FILE
rm LBA_$INPUT_FILE
rm Wear_$INPUT_FILE
