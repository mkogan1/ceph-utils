#!/bin/bash

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
    echo "missing  paramis: template filename, bktbegin, bktinc"
	exit 1
fi
TN=$1
ITBEGIN01=$2
ITINC01=$3

echo ">> Running with template: $TN"
AN=$(echo -n $TN | sed 's/__template.xml/__auto.xml/')
echo ">>              auto xml: $AN"

WCNT=1
while [ true ]; do
	ITEND01=$((ITBEGIN01+ITINC01-1))
    echo $'\n----------------------------------------'
    echo ">> Preparing workload #$WCNT :"
	echo "   ITBEGIN01=$ITBEGIN01 , ITEND01=$ITEND01"
	cp -v $TN $AN
	sed --in-place "s/#ITBEGIN01#/$ITBEGIN01/g" $AN
	sed --in-place "s/#ITEND01#/$ITEND01/g" $AN

	# wait until cosbench is free to take a workload
	echo ">> Waiting for cosbench to be ready for a new workload..."
	until [ $(../cosbench/cli.sh info 2>/dev/null | grep -c 'Total: 0 active workloads') -eq 1 ]; do
		echo -n "."
		sleep 2
	done
    echo $'\n>>>>>>>> cosbench ready >>>>>>>>>'
    date
    #sleep 30
	../../cosbench/cli.sh submit $AN 2>/dev/null

	ITBEGIN01=$((ITBEGIN01+ITINC01))
    WCNT=$((WCNT+1))

	#exit 1
done

exit 0
