#!/bin/bash
# author: Csoyee
# run rocksdb 
# >> use cp_rocksdb function for running customized rocksdb 


if [ $# -lt 2 ]
then 
	echo "Usage: $0 [DATA_PATH] [LOG_PATH] [YCSB_HOME]"
	exit 1
fi

PWD=`pwd`
DATA_PATH=$1
LOG_PATH=$2
YCSB_HOME=$3


# using customized rocksdb 
cp_rocksdb() {
	cd $YCSB_HOME

	if mvn -pl com.yahoo.ycsb:rocksdb-binding -am clean package; then
		echo "compiled"
	else 
		echo "YCSB version check! if ERROR - com.yahoo.ycsb --> site.ycsb"
	fi	


	rm ./rocksdb/target/dependency/rocksdbjni-*

	# change path if needed 
	ROCKSDB_PATH=../rocksdb/java/target/rocksdbjni-6.10.0.jar
	echo "ROCKSDB_PATH: $ROCKSDB_PATH"
	cp $ROCKSDB_PATH ./rocksdb/target/dependency/.

	cd $PWD
}

# run rocksdb 
run() {
	cd $YCSB_HOME

	echo "YCSB Thread: 4"
	echo "DATA DIR: $DATA_PATH"
	echo "LOG PATH: $LOG_PATH"
	echo "WORKLOAD: ./workload_run"

	./bin/ycsb.sh run rocksdb -s -threads 4 -P workload_run -p rocksdb.dir=${DATA_PATH} &> ${LOG_PATH}

	cd $PWD
}

