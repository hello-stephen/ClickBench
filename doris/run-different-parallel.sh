#!/bin/bash

set -e

DORIS_HOME='/home/ec2-user/ClickBench/doris/opt_perf-fee7e78954-release-20220926153547/output/'
# for p in 8 16 24 32 40 48;do
for p in 32 48 64 80 96 112 128 160 192;do
    echo $p

    set +e
    ./kill-doris-cluster.sh
    set -e

    # Start Frontend
    "$DORIS_HOME"/fe/bin/start_fe.sh --daemon

    # Start Backend
    sudo sysctl -w vm.max_map_count=2000000
    "$DORIS_HOME"/be/bin/start_be.sh --daemon

    sleep 20

    mysql -h 127.0.0.1 -P9030 -uroot -e "SET GLOBAL parallel_fragment_exec_instance_num=$p"
    mysql -h 127.0.0.1 -P9030 -uroot -e 'select @@parallel_fragment_exec_instance_num'

    suffix=$(date +%Y%m%d%H%M%S)
    result_log="ckb_result_${suffix}.log"
    rumtime_log="runtime_${suffix}.log"
    echo "opt_perf-fee7e78954-release-20220926153547" | tee run.log
    # head -n1 run.log | tee run.log

    bash get-compaction-info.sh >"$rumtime_log"
    ./run.sh 2>&1 | tee -a run.log

    {
        bash get-doris-runtime-conf.sh
        bash get-table-schema.sh
        bash get-mechine-info.sh
    } >>"$rumtime_log"
    bash get-ckb-score.sh >"$result_log"

    sed -i "s/parallel_fragment_exec_instance_num=.*/parallel_fragment_exec_instance_num=$p;/g" note_file

    python3 upload-ckb-to-feishu.py "$result_log" "$rumtime_log" "note_file"

    ./kill-doris-cluster.sh

    sleep 10

done
