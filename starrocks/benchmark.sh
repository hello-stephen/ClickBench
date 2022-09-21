#!/bin/bash

StarRocks-2.3.0-rc03/fe/bin/stop_fe.sh ; StarRocks-2.3.0-rc03/be/bin/stop_be.sh ; rm -rf StarRocks-2.3.0-rc03

# This benchmark should run on Amazon Linux

# Install
# wget https://download.starrocks.com/en-US/download/request-download/40/StarRocks-2.3.0-rc03.tar.gz
tar zxvf StarRocks-2.3.0-rc03.tar.gz
cd StarRocks-2.3.0-rc03/

# Install dependencies
sudo yum install -y java-1.8.0-openjdk-devel.x86_64 mysql

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk/
export PATH=$JAVA_HOME/bin:$PATH

# Create directory for FE and BE
IPADDR=`hostname -i`
export STARROCKS_HOME=`pwd`
mkdir -p meta storage

# Start Frontend
echo "meta_dir = ${STARROCKS_HOME}/meta " >> fe/conf/fe.conf
fe/bin/start_fe.sh --daemon

# Start Backend
echo "storage_root_path = ${STARROCKS_HOME}/storage" >> be/conf/be.conf

# This if you want to obtain the "tuned" result:
echo "disable_storage_page_cache = false" >> be/conf/be.conf
echo "storage_page_cache_limit = 4G" >> be/conf/be.conf
echo "mem_limit=90%" >> be/conf/be.conf

be/bin/start_be.sh --daemon
sleep 20
cd ..
# Setup cluster
mysql -h 127.0.0.1 -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND '${IPADDR}:9050' "
sleep 20
mysql -h 127.0.0.1 -P9030 -uroot -e "CREATE DATABASE hits"
mysql -h 127.0.0.1 -P9030 -uroot hits < create.sql

# This if you want to obtain the "tuned" result:
mysql -h 127.0.0.1 -P9030 -uroot -e "SET GLOBAL enable_column_expr_predicate=true"

# # Load data
# wget --continue 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
# gzip -d hits.tsv.gz
# # Split file into chunks
# split -a 1 -d -l 10000000 hits.tsv hits_split

START=$(date +%s)
for i in `seq -w 0 9`; do
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

# This if you want to obtain the "tuned" result. Analyze table:
time mysql -h 127.0.0.1 -P9030 -uroot hits -e "ANALYZE TABLE hits"

# Dataset contains 23676271984 bytes and 99997497 rows
du -bcs StarRocks-2.3.0-rc03/storage/
mysql -h 127.0.0.1 -P9030 -uroot hits -e "SELECT count(*) FROM hits"

# Run queries
./run.sh 2>&1 | tee run.log

# sed -r -e 's/query[0-9]+,/[/; s/$/],/' run.log