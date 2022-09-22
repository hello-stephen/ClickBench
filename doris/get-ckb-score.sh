#!/bin/bash
# input:  result.csv(generated by run.sh), run.log(generated by benchmark.sh)
# output:
# 
# Doris version:  master-32551a726-release-20220922095904
# Relative time(to total, geometric mean of column ratio_of_total):       4.629280754082786
# Relative time(to machine, , geometric mean of column ratio_of_machine): 1.8770800411488593
# column best:                    best of hot1 and hot2
# column total_baseline:          data from https://benchmark.clickhouse.com/
# column ratio_of_total:          (best+0.01)/(total_baseline+0.01)
# column machine_baseline:        data from https://benchmark.clickhouse.com/, mechine is c6a.4xlarge,500gb gp2
# column ratio_of_machine:        (best+0.01)/(machine_baseline+0.01)
# 
# query   cold    hot1    hot2    best    total_baseline  ratio_of_total  machine_baseline        ratio_of_machine
# query1  1.11    0.03    0.03    0.03    0.000155000     3.938946332     0.000155000     3.938946332
# query2  0.12    0.03    0.03    0.03    0.010000000     2.000000000     0.010000000     2.000000000
# query3  1.10    0.05    0.05    0.05    0.010000000     3.000000000     0.033000000     1.395348837
# query4  1.55    0.05    0.05    0.05    0.010000000     3.000000000     0.029207000     1.530338970
# query5  1.57    1.54    1.53    1.53    0.109031000     12.937806118    0.620000000     2.444444444
# query6  1.26    0.89    0.89    0.89    0.176052000     4.837357298     0.930000000     0.957446809
# query7  0.14    1.08    0.10    0.10    0.010000000     5.500000000     0.024000000     3.235294118
# query8  0.02    0.03    0.03    0.03    0.010000000     2.000000000     0.015000000     1.600000000
# query9  0.76    0.78    0.74    0.74    0.133104000     5.240943649     0.580000000     1.271186441
# query10 0.85    0.85    0.87    0.85    0.284000000     2.925170068     0.680000000     1.246376812
# query11 0.23    0.18    0.18    0.18    0.088729000     1.924459885     0.090000000     1.900000000
# query12 0.22    0.20    0.20    0.20    0.080000000     2.333333333     0.090000000     2.100000000
# query13 0.68    0.69    0.64    0.64    0.158393000     3.860017934     0.294000000     2.138157895
# query14 1.15    1.38    1.41    1.38    0.213000000     6.233183857     1.029000000     1.337824832
# query15 1.16    1.06    1.00    1.00    0.174000000     5.489130435     0.897000000     1.113561191
# query16 0.42    0.43    0.45    0.43    0.143406000     2.868205937     0.550000000     0.785714286
# query17 1.40    1.37    1.37    1.37    0.339775000     3.945393467     2.350000000     0.584745763
# query18 0.26    0.35    0.31    0.31    0.275000000     1.122807018     0.370000000     0.842105263
# query19 2.88    2.76    2.87    2.76    0.506000000     5.368217054     4.380000000     0.630979499
# query20 0.02    0.02    0.04    0.02    0.000157442     2.953499513     0.000157442     2.953499513
# query21 10.97   0.88    0.89    0.88    0.070000000     11.125000000    0.070000000     11.125000000
# query22 9.78    2.59    0.75    0.75    0.140000000     5.066666667     0.395884000     1.872456170
# query23 12.60   0.85    0.83    0.83    0.310000000     2.625000000     0.395477000     2.071634149
# query24 33.02   2.18    2.11    2.11    0.046760200     37.350115045    0.335000000     6.144927536
# query25 1.36    0.20    0.21    0.20    0.002459360     16.854798320    0.005000000     14.000000000
# query26 0.19    0.18    0.19    0.18    0.045000000     3.454545455     0.130000000     1.357142857
# query27 0.22    0.21    0.22    0.21    0.058000000     3.235294118     0.139861000     1.468027038
# query28 10.72   1.39    1.39    1.39    0.130000000     10.000000000    0.733000000     1.884253028
# query29 8.83    3.49    3.69    3.49    0.483000000     7.099391481     5.570000000     0.627240143
# query30 0.89    0.80    0.70    0.70    0.203014000     3.333114255     0.713598326     0.981207356
# query31 1.86    0.61    0.59    0.59    0.113000000     4.878048780     0.520000000     1.132075472
# query32 2.14    0.69    0.66    0.66    0.175000000     3.621621622     0.712000000     0.927977839
# query33 3.32    3.63    3.82    3.63    0.048000000     62.758620690    4.820000000     0.753623188
# query34 12.68   4.93    4.70    4.70    0.494000000     9.345238095     0.494000000     9.345238095
# query35 10.72   5.01    4.87    4.87    0.544000000     8.808664260     4.035000000     1.206427689
# query36 1.42    1.34    1.35    1.34    0.137629000     9.144544771     1.188000000     1.126878130
# query37 0.21    0.15    0.15    0.15    0.040539136     3.165863382     0.040539136     3.165863382
# query38 0.14    0.13    0.14    0.13    0.019683109     4.716487077     0.019683109     4.716487077
# query39 0.08    0.06    0.05    0.05    0.010000000     3.000000000     0.010000000     3.000000000
# query40 0.19    0.20    0.21    0.20    0.085472760     2.199580278     0.085472760     2.199580278
# query41 0.06    0.05    0.05    0.05    0.007633564     3.402601992     0.007633564     3.402601992
# query42 0.06    0.06    0.05    0.05    0.007858586     3.359728480     0.007858586     3.359728480
# query43 0.03    0.03    0.03    0.03    0.010000000     2.000000000     0.010000000     2.000000000
# total   138.39  43.43   40.44   39.78
#


total_baseline=(0.000155 0.01 0.01 0.01 0.109031 0.176052 0.01 0.01 0.133104 0.284 0.088729 0.08 0.158393 0.213 0.174 0.143406 0.339775 0.275 0.506 0.000157442 0.07 0.14 0.31 0.0467602 0.00245936 0.045 0.058 0.13 0.483 0.203014 0.113 0.175 0.048 0.494 0.544 0.137629 0.040539136 0.019683109 0.01 0.08547276 0.007633564 0.007858586 0.01)

machine_baseline=(0.000155 0.01 0.033 0.029207 0.62 0.93 0.024 0.015 0.58 0.68 0.09 0.09 0.294 1.029 0.897 0.55 2.35 0.37 4.38 0.000157442 0.07 0.395884 0.395477 0.335 0.005 0.13 0.139861 0.733 5.57 0.713598326 0.52 0.712 4.82 0.494 4.035 1.188 0.040539136 0.019683109 0.01 0.08547276 0.007633564 0.007858586 0.01 )

awk -F ',' '{if($3<$4){print $3}else{print $4}}' result.csv > best_hot.csv
i=0
product=1
while read doris;do
    r=$(echo "scale=9;(${doris} + 0.01) / (${total_baseline[$i]} + 0.01)" | bc)
    let i++
    product=$(echo "scale=9; $product * $r" | bc)
done < best_hot.csv
total_score=$(echo "print(pow($product, 1.0/43))" | python3)

i=0
product=1
while read doris;do
    r=$(echo "scale=9;(${doris} + 0.01) / (${machine_baseline[$i]} + 0.01)" | bc)
    let i++
    product=$(echo "scale=9; $product * $r" | bc)
done < best_hot.csv
machine_score=$(echo "print(pow($product, 1.0/43))" | python3)

total_cold=$(awk -F ',' '{sum+=$2} END {print sum}' result.csv)
total_hot1=$(awk -F ',' '{sum+=$3} END {print sum}' result.csv)
total_hot2=$(awk -F ',' '{sum+=$4} END {print sum}' result.csv)
total_best_hot=$(awk -F ',' '{if($3<$4){sum+=$3}else{sum+=$4}} END {print sum}' result.csv)
echo "${total_baseline[*]}" | tr ' ' '\n' | awk '{printf("%.9f\n", $1)}' > total_baseline.csv
paste best_hot.csv total_baseline.csv | awk '{r=($1+0.01)/($2+0.01); printf("%.9f\n", r)}' >hot_ratio_to_total_baseline.csv
echo "${machine_baseline[*]}" | tr ' ' '\n' | awk '{printf("%.9f\n", $1)}' > machine_baseline.csv
paste best_hot.csv machine_baseline.csv | awk '{r=($1+0.01)/($2+0.01); printf("%.9f\n", r)}' >hot_ratio_to_machine_baseline.csv


echo -e "Doris version:\t$(head -n1 run.log)"
echo -e "Relative time(to total, geometric mean of column ratio_of_total):\t$total_score"
echo -e "Relative time(to machine, geometric mean of column ratio_of_machine):\t$machine_score"
echo -e "column best:\t\t\tbest of hot1 and hot2"
echo -e "column total_baseline:\t\tdata from https://benchmark.clickhouse.com/"
echo -e "column ratio_of_total:\t\t(best+0.01)/(total_baseline+0.01)"
echo -e "column machine_baseline:\tdata from https://benchmark.clickhouse.com/, mechine is c6a.4xlarge,500gb gp2"
echo -e "column ratio_of_machine:\t(best+0.01)/(machine_baseline+0.01)"
echo
echo -e "query \tcold \thot1 \thot2 \tbest \ttotal_baseline \tratio_of_total \tmachine_baseline \tratio_of_machine"
paste result.csv best_hot.csv total_baseline.csv hot_ratio_to_total_baseline.csv machine_baseline.csv hot_ratio_to_machine_baseline.csv | tr ',' '\t'
echo -e "total\t${total_cold}\t${total_hot1}\t${total_hot2}\t${total_best_hot}"
rm -f best_hot.csv total_baseline.csv hot_ratio_to_total_baseline.csv machine_baseline.csv hot_ratio_to_machine_baseline.csv
echo
