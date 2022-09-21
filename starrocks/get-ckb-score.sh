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


echo -e "Relative time(to total):\t$total_score"
echo -e "Relative time(to machine):\t$machine_score"
echo -e "machine: c6a.4xlarge,500gb gp2"
echo -e "query \tcold \thot1 \thot2 \tbest \ttotal_baseline \tratio_of_total \tmachine_baseline \tratio_of_machine"
paste result.csv best_hot.csv total_baseline.csv hot_ratio_to_total_baseline.csv machine_baseline.csv hot_ratio_to_machine_baseline.csv | tr ',' '\t'
echo -e "total\t${total_cold}\t${total_hot1}\t${total_hot2}\t${total_best_hot}"
rm -f best_hot.csv total_baseline.csv hot_ratio_to_total_baseline.csv machine_baseline.csv hot_ratio_to_machine_baseline.csv