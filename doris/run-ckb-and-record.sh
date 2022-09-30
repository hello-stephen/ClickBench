#!/bin/bash
./kill-doris-cluster.sh
pip3 install requests
set -e

suffix=$(date +%Y%m%d%H%M%S)
result_log="ckb_result_${suffix}.log"
rumtime_log="runtime_${suffix}.log"

source benchmark.sh "$1" >"run-ckb-and-record-$suffix.log"
date
bash get-compaction-info.sh >"$rumtime_log"
./run.sh 2>&1 | tee -a run.log

bash get-doris-runtime-conf.sh >>"$rumtime_log"
bash get-table-schema.sh >>"$rumtime_log"
bash get-ckb-score.sh >"$result_log"
echo 'load and run' >>"$result_log"

python3 upload-ckb-to-feishu.py "$result_log" "$rumtime_log" "note_file"
exit
##########################################
date
echo "after first run, wait 60s then run again"
sleep 60

suffix=$(date +%Y%m%d%H%M%S)
result_log="ckb_result_${suffix}.log"
rumtime_log="runtime_${suffix}.log"
# echo "optimize_dict-c5b3463fb-release-20220922181457" | tee run.log
head -n1 run.log | tee run.log

bash get-compaction-info.sh >"$rumtime_log"
./run.sh 2>&1 | tee -a run.log

{
    bash get-doris-runtime-conf.sh
    bash get-table-schema.sh
    bash get-mechine-info.sh
} >>"$rumtime_log"
bash get-ckb-score.sh >"$result_log"
echo 'after first run, wait 60s then run again' >>"$result_log"

python3 upload-ckb-to-feishu.py "$result_log" "$rumtime_log" "note_file"

./kill-doris-cluster.sh
