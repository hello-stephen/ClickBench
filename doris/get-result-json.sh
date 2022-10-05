#!/bin/bash

# set -x

echo -e "{
    \"system\": \"SelectDB-2.0.0\",
    \"date\": \"$(date '+%Y-%m-%d')\",
    \"machine\": \"$(sudo dmidecode -s system-product-name), 500gb gp2\",
    \"cluster_size\": 1,
    \"comment\": \"\",
    \"tags\": [\"C++\", \"column-oriented\", \"MySQL compatible\", \"ClickHouse derivative\"],
    \"load_time\": $(cat loadtime),
    \"data_size\": $(cat storage_size),
    \"result\": [
$(r=$(sed -r -e 's/query[0-9]+,/[/; s/$/],/' result.csv); echo "${r%?}")
    ]
}
" | tee result.json
