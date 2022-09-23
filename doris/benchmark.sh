#!/bin/bash

# This benchmark should run on Amazon Linux

# Install
ROOT=$(pwd)

if [[ -n "$1" ]]; then
    url="$1"
else
    url='https://doris-build-1308700295.cos.ap-beijing.myqcloud.com/tmp/opt_perf-3d2a73c02-release-20220922221410.tar.gz'
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

# Install dependencies
sudo yum install -y mysql java-11-openjdk.x86_64
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk/"
export PATH=$JAVA_HOME/bin:$PATH

# Start Frontend
"$DORIS_HOME"/fe/bin/start_fe.sh --daemon

# Start Backend
IPADDR=$(hostname -i)
# This if you want to obtain the "tuned" result:
echo "
doris_scanner_thread_pool_thread_num=8
tc_enable_aggressive_memory_decommit=false
enable_new_scan_node=false
mem_limit=95%
# disable_auto_compaction=true
priority_networks = ${IPADDR}/24
" >"$DORIS_HOME"/be/conf/be_custom.conf

sudo sysctl -w vm.max_map_count=2000000
"$DORIS_HOME"/be/bin/start_be.sh --daemon

# wait for Doris ready
while true; do
    fe_version=$(mysql -h127.0.0.1 -P9030 -uroot -e 'show frontends' | cut -f16 | sed -n '2,$p')
    if [[ -n "${fe_version}" ]] && [[ "${fe_version}" != "NULL" ]]; then
        echo "fe version: ${fe_version}"
        break
    else
        echo 'wait for Doris fe started.'
    fi
    sleep 2
done
mysql -h 127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND '${IPADDR}:9050' "
while true; do
    be_version=$(mysql -h127.0.0.1 -P9030 -uroot -e 'show backends' | cut -f22 | sed -n '2,$p')
    if [[ -n "${be_version}" ]]; then
        echo "be version: ${be_version}"
        curl '127.0.0.1:8040/varz' | grep 'doris_scanner_thread_pool_thread_num\|tc_enable_aggressive_memory_decommit\|enable_new_scan_node\|mem_limit\|disable_auto_compaction'
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

# This if you want to obtain the "tuned" result:
opt_session_variables="
exec_mem_limit=32G;
parallel_fragment_exec_instance_num=16;
enable_single_distinct_column_opt=true;
enable_function_pushdown=true;
enable_local_exchange=true;
"
for session_variable in ${opt_session_variables}; do
    mysql -h 127.0.0.1 -P9030 -uroot -e "SET GLOBAL ${session_variable}"
done
mysql -h 127.0.0.1 -P9030 -uroot -e 'show variables' | grep 'exec_mem_limit\|parallel_fragment_exec_instance_num\|enable_single_distinct_column_opt\|enable_function_pushdown\|enable_local_exchange\|load_mem_limit'

# Load data

# wget --continue 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
# gzip -d hits.tsv.gz
# # Split file into chunks
# split -a 1 -d -l 10000000 hits.tsv hits_split

date
START=$(date +%s)
for i in $(seq -w 0 9); do
    echo "start loading hits_split${i} ..."
    curl --location-trusted \
        -u root: \
        -T "hits_split${i}" \
        -H "label:hits_split${i}" \
        -H "columns: WatchID,JavaEnable,Title,GoodEvent,EventTime,EventDate,CounterID,ClientIP,RegionID,UserID,CounterClass,OS,UserAgent,URL,Referer,IsRefresh,RefererCategoryID,RefererRegionID,URLCategoryID,URLRegionID,ResolutionWidth,ResolutionHeight,ResolutionDepth,FlashMajor,FlashMinor,FlashMinor2,NetMajor,NetMinor,UserAgentMajor,UserAgentMinor,CookieEnable,JavascriptEnable,IsMobile,MobilePhone,MobilePhoneModel,Params,IPNetworkID,TraficSourceID,SearchEngineID,SearchPhrase,AdvEngineID,IsArtifical,WindowClientWidth,WindowClientHeight,ClientTimeZone,ClientEventTime,SilverlightVersion1,SilverlightVersion2,SilverlightVersion3,SilverlightVersion4,PageCharset,CodeVersion,IsLink,IsDownload,IsNotBounce,FUniqID,OriginalURL,HID,IsOldCounter,IsEvent,IsParameter,DontCountHits,WithHash,HitColor,LocalEventTime,Age,Sex,Income,Interests,Robotness,RemoteIP,WindowName,OpenerName,HistoryLength,BrowserLanguage,BrowserCountry,SocialNetwork,SocialAction,HTTPError,SendTiming,DNSTiming,ConnectTiming,ResponseStartTiming,ResponseEndTiming,FetchTiming,SocialSourceNetworkID,SocialSourcePage,ParamPrice,ParamOrderID,ParamCurrency,ParamCurrencyID,OpenstatServiceName,OpenstatCampaignID,OpenstatAdID,OpenstatSourceID,UTMSource,UTMMedium,UTMCampaign,UTMContent,UTMTerm,FromTag,HasGCLID,RefererHash,URLHash,CLID" \
        http://localhost:8030/api/hits/hits/_stream_load
done
END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load data costs $LOADTIME seconds"
date

# This if you want to obtain the "tuned" result. Analyze table:
#time mysql -h 127.0.0.1 -P9030 -uroot hits -e "ANALYZE TABLE hits"

# Dataset contains 23676271984 bytes and 99997497 rows
du -bcs "$DORIS_HOME"/be/storage/
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
