#!/bin/bash
set -ex

# This benchmark should run on Amazon Linux

# Install
ROOT=$(pwd)

if [[ -n "$1" ]]; then
    url="$1"
else
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-3d2a73c02-release-20220922221410.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-72fdfc0e3-release-20220923220301.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-c4386d863-release-20220924145346.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-31f38a5c2-release-20220925102436.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-5c6c13e946-release-20220926141740.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-06e646a551-release-20220926190600.tar.gz'
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf_topn-bbc791e774-release-20220929155416.tar.gz'
    # url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf_topn-c573221af7-release-20220929200042.tar.gz'
fi
echo "Source bin from $url"

file_name="$(basename ${url})"
if [[ "$url" == "http"* ]]; then
    if [[ ! -f $file_name ]]; then
        wget --continue ${url}
    else
        echo "$file_name already exists."
    fi
fi
dir_name="$(basename ${url} | cut -d'.' -f1)"

set +e
"$dir_name"/output/fe/bin/stop_fe.sh
"$dir_name"/output/be/bin/stop_be.sh
rm -rf "$dir_name"
set -e

mkdir "$dir_name"
tar zxvf "$file_name" -C "$dir_name"
DORIS_HOME="$ROOT/$dir_name/output/"
export DORIS_HOME
echo "$DORIS_HOME" >doris_home

# Install dependencies
sudo yum install -y mysql java-11-amazon-corretto.x86_64
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk/"
export PATH=$JAVA_HOME/bin:$PATH

IPADDR=$(hostname -i)
# This if you want to obtain the "tuned" result:
echo "
stream_load_default_timeout_second=3600
priority_networks = ${IPADDR}/24
" >"$DORIS_HOME"/fe/conf/fe_custom.conf
echo >note_file
cat "$DORIS_HOME"/fe/conf/fe_custom.conf >>note_file
echo >>note_file


sed -i 's/-XX:OnOutOfMemoryError/ -Dnetworkaddress.cache.ttl=100000 -XX:OnOutOfMemoryError/g' "$DORIS_HOME"/fe/bin/start_fe.sh
tail -n 10 "$DORIS_HOME"/fe/bin/start_fe.sh

echo "
streaming_load_max_mb=102400
doris_scanner_thread_pool_thread_num=8
tc_enable_aggressive_memory_decommit=false
enable_new_scan_node=false
mem_limit=95%
write_buffer_size=1609715200
load_process_max_memory_limit_percent=90
disable_auto_compaction=true
priority_networks = ${IPADDR}/24
" >"$DORIS_HOME"/be/conf/be_custom.conf
cat "$DORIS_HOME"/be/conf/be_custom.conf >>note_file
echo >>note_file

opt_session_variables="
exec_mem_limit=32G;
parallel_fragment_exec_instance_num=16;
enable_single_distinct_column_opt=true;
enable_function_pushdown=true;
enable_local_exchange=true;
load_mem_limit=34359738368;
"
echo -e "$opt_session_variables" >>note_file

# Start Frontend
"$DORIS_HOME"/fe/bin/start_fe.sh --daemon

# Start Backend
sudo sysctl -w vm.max_map_count=2000000
"$DORIS_HOME"/be/bin/start_be.sh --daemon

# wait for Doris FE ready
while true; do
    fe_version=$(mysql -h127.0.0.1 -P9030 -uroot -e 'show frontends' | cut -f16 | sed -n '2,$p')
    if [[ -n "${fe_version}" ]] && [[ "${fe_version}" != "NULL" ]]; then
        echo "fe version: ${fe_version}"
        mysql -h127.0.0.1 -P9030 -uroot -e 'admin show frontend config;' | grep 'write_buffer_size\|stream_load_default_timeout_second\|priority_networks'
        break
    else
        echo 'wait for Doris fe started.'
    fi
    sleep 2
done
# add BE to cluster
mysql -h 127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND '${IPADDR}:9050' "
# wait for Doris BE ready
while true; do
    be_version=$(mysql -h127.0.0.1 -P9030 -uroot -e 'show backends' | cut -f22 | sed -n '2,$p')
    if [[ -n "${be_version}" ]]; then
        echo "be version: ${be_version}"
        curl '127.0.0.1:8040/varz' | grep 'load_process_max_memory_limit_percent\|chunk_reserved_bytes_limit\|storage_page_cache_limit\|streaming_load_max_mb\|doris_scanner_thread_pool_thread_num\|tc_enable_aggressive_memory_decommit\|enable_new_scan_node\|mem_limit\|disable_auto_compaction\|priority_networks'
        break
    else
        echo 'wait for Doris be started.'
    fi
    sleep 2
done

# Setup cluster
mysql -h 127.0.0.1 -P9030 -uroot -e "CREATE DATABASE hits"
sleep 10
mysql -h 127.0.0.1 -P9030 -uroot hits <"$ROOT"/create.sql

for session_variable in ${opt_session_variables}; do
    mysql -h 127.0.0.1 -P9030 -uroot -e "SET GLOBAL ${session_variable}"
done
mysql -h 127.0.0.1 -P9030 -uroot -e 'show variables' | grep 'load_mem_limit\|exec_mem_limit\|parallel_fragment_exec_instance_num\|enable_single_distinct_column_opt\|enable_function_pushdown\|enable_local_exchange'

# Load data

if [[ ! -f hits.tsv.gz ]] && [[ ! -f hits.tsv ]]; then
    wget --continue 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
    gzip -d hits.tsv.gz
fi
# # Split file into chunks
# # split -a 1 -d -l 10000000 hits.tsv hits_split

date
START=$(date +%s)
for i in hits*.tsv; do
    echo "start loading ${i} ..."
    curl --location-trusted \
        -u root: \
        -T "${i}" \
        -H "label:hits" \
        -H "columns: WatchID,JavaEnable,Title,GoodEvent,EventTime,EventDate,CounterID,ClientIP,RegionID,UserID,CounterClass,OS,UserAgent,URL,Referer,IsRefresh,RefererCategoryID,RefererRegionID,URLCategoryID,URLRegionID,ResolutionWidth,ResolutionHeight,ResolutionDepth,FlashMajor,FlashMinor,FlashMinor2,NetMajor,NetMinor,UserAgentMajor,UserAgentMinor,CookieEnable,JavascriptEnable,IsMobile,MobilePhone,MobilePhoneModel,Params,IPNetworkID,TraficSourceID,SearchEngineID,SearchPhrase,AdvEngineID,IsArtifical,WindowClientWidth,WindowClientHeight,ClientTimeZone,ClientEventTime,SilverlightVersion1,SilverlightVersion2,SilverlightVersion3,SilverlightVersion4,PageCharset,CodeVersion,IsLink,IsDownload,IsNotBounce,FUniqID,OriginalURL,HID,IsOldCounter,IsEvent,IsParameter,DontCountHits,WithHash,HitColor,LocalEventTime,Age,Sex,Income,Interests,Robotness,RemoteIP,WindowName,OpenerName,HistoryLength,BrowserLanguage,BrowserCountry,SocialNetwork,SocialAction,HTTPError,SendTiming,DNSTiming,ConnectTiming,ResponseStartTiming,ResponseEndTiming,FetchTiming,SocialSourceNetworkID,SocialSourcePage,ParamPrice,ParamOrderID,ParamCurrency,ParamCurrencyID,OpenstatServiceName,OpenstatCampaignID,OpenstatAdID,OpenstatSourceID,UTMSource,UTMMedium,UTMCampaign,UTMContent,UTMTerm,FromTag,HasGCLID,RefererHash,URLHash,CLID" \
        http://localhost:8030/api/hits/hits/_stream_load
done
END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load data costs $LOADTIME seconds"
export LOADTIME
echo "$LOADTIME" >loadtime
date

# This if you want to obtain the "tuned" result. Analyze table:
#time mysql -h 127.0.0.1 -P9030 -uroot hits -e "ANALYZE TABLE hits"

# Dataset contains 23676271984 bytes and 99997497 rows
du -bs "$DORIS_HOME"/be/storage/ | cut -f1 | tee storage_size
mysql -h 127.0.0.1 -P9030 -uroot hits -e "SELECT count(*) FROM hits"
date

# Run queries
echo "$dir_name" | tee run.log
# ./run.sh 2>&1 | tee -a run.log
date

# sed -r -e 's/query[0-9]+,/[/; s/$/],/' run.log

set +e
# "$dir_name"/output/fe/bin/stop_fe.sh
# "$dir_name"/output/be/bin/stop_be.sh
# rm -rf "$dir_name"
set -e
