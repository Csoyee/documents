#!/bin/bash


## Author csoyee
## get log :: sudo smartctl -A ${BLKDEV} every 300 seconds
## output file :: run_waf - running waf every 300 seconds , cum_waf - cumulative waf


if [ $# -lt 1 ]
then
	echo "Usage $0 [inputfilename]"
	exit 1
fi


INPUT_FILE=$1

cat $INPUT_FILE | grep "^247" | awk '{print $10}' >  LBA_$INPUT_FILE
cat $INPUT_FILE | grep "^248" | awk '{print $10}' >  SSD_$INPUT_FILE

First_LBA=$(head -n 1 LBA_${INPUT_FILE})
First_SSD=$(head -n 1 SSD_${INPUT_FILE})

echo $First_LBA
echo $First_SSD

bef_lba=$First_LBA
bef_ssd=$First_SSD

count=1

rm run_waf
rm cum_waf

while true
do
	read -r lba <&3 || break
	read -r ssd <&4 || break

	if [ $(($lba-$First_LBA)) -ne 0 ]
	then
		echo -n "$((($count-1)*300)) ">> cum_waf
		echo "scale=3; (($lba-$First_LBA + $ssd-$First_SSD) / ($lba-$First_LBA))" | bc >> cum_waf
		echo -n "$((($count-1)*300)) ">> w_$INPUT_FILE
		echo "(($ssd-$First_SSD))" | bc >> w_$INPUT_FILE
		echo -n "$((($count-1)*300)) ">> l_$INPUT_FILE
		echo "(($lba-$First_LBA))" | bc >> l_$INPUT_FILE
	fi

	if [ $(($lba-$bef_lba)) -ne 0 ]
	then
		if (( (($count%1)) == 0 ))
		then
			echo -n "$((($count-1)*300)) " >> run_waf
			echo "scale=3; (($ssd-$bef_ssd + $lba-$bef_lba) / ($lba-$bef_lba))" | bc >> run_waf
			bef_lba=$lba
			bef_ssd=$ssd
		fi
	fi


	count=$(($count+1))
done 3< LBA_$INPUT_FILE 4<SSD_$INPUT_FILE


tail -n 1 run_waf
tail -n 1 cum_waf


rm w_$INPUT_FILE
rm l_$INPUT_FILE
rm LBA_$INPUT_FILE
rm SSD_$INPUT_FILE
