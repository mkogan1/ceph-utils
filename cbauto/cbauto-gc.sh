#!/bin/bash

# INSTRUCTIONS: change the IP address below to the IP of the rgw and 
# copy the /root/.ssh/id_rsa file from the jumphost to the ~/ directory
RGWHOST=192.168.205.149

echo "checking that the RGW host at ip: $RGWHOST"
echo "is accessible vis ssh to call radosgw-admin gc process.."
ssh -i ~/id_rsa $RGWHOST radosgw-admin --version
read -p "if the Ceph version is shown, press <enter> to continue"


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
    if [[ $? -eq 0 ]]; then
        PF=$(ssh -i ~/id_rsa $RGWHOST ceph df | grep -A 1 SIZE | tail -1 | awk '{ print $4 }' | cut -d . -f 1)
        echo ">> Checing GC - percent full= $PF %"
        #exit 1
        if [[ $PF -ge 50 ]]; then
            echo "   >> GC process ..."
            #radosgw-admin gc process --include-all
            time ssh -i ~/id_rsa $RGWHOST radosgw-admin gc process --include-all &> /tmp/radosgw-admin.log
            echo "   >> GC complete"
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
