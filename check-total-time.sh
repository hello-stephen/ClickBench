#!/bin/bash
result_url='clickhouse/results/c6a.metal.json'
result_url='clickhouse/results/c6a.4xlarge.json'
# result_url='clickhouse/results/c6a.4xlarge.zstd.json'
# result_url='selectdb/results/c6a.metal.json'

file_name=$(basename $result_url)
# wget "$result_url"
echo -n 'cold-sum: '
grep "^\[" "$result_url" | sed -e 's/\[//; s/\]//; s/\,/ /g' | awk '{sum+=$1} END {print sum}'

echo -n 'hot-sum: '
grep "^\[" "$result_url" | sed -e 's/\[//; s/\]//; s/\,/ /g' | awk '{if($2<$3){sum+=$2}else{sum+=$3}} END {print sum}'
