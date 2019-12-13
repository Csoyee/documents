# TPCC MySQL


## reference
- [TPC-C github](https://github.com/Percona-Lab/tpcc-mysql)


## Get Source 
```bash
$ git clone https://github.com/Percona-Lab/tpcc-mysql
$ cd tpcc-mysql 
```

## Build Binaries

- you should have mysql_config available in `$PATH` beforehand.
```bash
$ echo $PATH
[other/path]:/home/csoyee/MYSQL/bin
```
- build binaries

```bash
$ cd src 
$ make 
```

## Load Data

1. create database

```bash
$ mysqladmin create tpcc1000
```

2. create tables and indexes

```bash
$ mysql tpcc1000 < create_table.sql
$ mysql tpcc1000 < add_fkey_idx.sql
```

3. populate data

```bash
# |hostname:port| |dbname| |user| |password| |WAREHOUSES| 
$ tpcc_load -h127.0.0.1 -d tpcc1000 -u root -p "" -w 1000 
```

## Start Benchmark
```bash
# |hostname| |port| |dbname| |user| |WAREHOUSES| |CONNECTIONS| |WARMUP TIME| |BENCHMARK TIME|
$ ./tpcc_start -h127.0.0.1 -P3306 -dtpcc1000 -uroot -w1000 -c32 -r10 -l10800
```
