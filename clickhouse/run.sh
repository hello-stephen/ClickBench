#!/bin/bash

TRIES=3
QUERY_NUM=1
cat /home/ec2-user/ClickBench/doris/queries-sort.sql | while read query; do
    echo $query
    clickhouse-client --query="$query" >ck-q${QUERY_NUM}.result
    QUERY_NUM=$((QUERY_NUM + 1))
done
