awk -F ',' '{if($3<$4){print $3}else{print $4}}' result.csv > hot.tmp

paste -d'\t' result.csv hot.tmp

cat hot.tmp

rm hot.tmp
