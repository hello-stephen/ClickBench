#!/bin/bash

set -e

echo -e "\n\n\n\n
#############################
table schema
mysql -h127.1 -P9030 -uroot -Dhits -e'show create table hits;'
#############################
"
s=$(mysql -h127.1 -P9030 -uroot -Dhits -e'show create table hits;')
echo -e $s
