#!/bin/bash

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
    echo "missing  paramis: template filename, bktbegin, bktinc"
	exit 1
fi
TN=$1
ITBEGIN01=$2
ITINC01=$3

echo ">> Running with template: $TN"
AN=$(echo -n "/tmp/$TN" | sed 's/__template.xml/__auto.xml/')
echo ">>              auto xml: $AN"
#exit 1;

WCNT=1
while [ true ]; do
    echo $'\n----------------------------------------'
    # check if should purge
    CP=$(which ceph)
    if [[ $? -eq 0 ]]; then 
        PF=$($CP df | grep -A 1 SIZE | tail -1 | awk '{ print $4 }' | cut -d . -f 1)
        echo ">> Checing purge - percent full= $PF %"
        #exit 1
        if [[ $PF -ge 79 ]]; then
            echo "   >> Purging ..."
            pushd ../../cosbench
            ./stop-all.sh
            popd
            ../scripts/rados_purge.sh
            #../scripts/swift_init.sh
            pushd ../../cosbench
            ./start-all.sh
            popd
            echo "   >> Purging complete"
        fi
    fi

	ITEND01=$((ITBEGIN01+ITINC01-1))
    echo ">> Preparing workload #$WCNT :"
	echo "   ITBEGIN01=$ITBEGIN01 , ITEND01=$ITEND01"
    echo -n "   cp "
	cp -v $TN $AN
	sed --in-place "s/#ITBEGIN01#/$ITBEGIN01/g" $AN
	sed --in-place "s/#ITEND01#/$ITEND01/g" $AN

	# wait until cosbench is free to take a workload
	echo ">> Waiting for cosbench to complete the running workload..."
	until [ $(../../cosbench/cli.sh info 2>/dev/null | grep -c 'Total: 0 active workloads') -eq 1 ]; do
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
