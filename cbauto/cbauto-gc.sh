#!/bin/bash

# INSTRUCTIONS: change the IP address below to the IP of the rgw and
# copy the /root/.ssh/id_rsa file from the jumphost to the ./key directory
if [ ! -n "${RGWHOST}" ]; then
   #RGWHOST=192.168.205.149  ## sasl
   RGWHOST=b08-h31-1029p  ## bagl
fi
# perform gc betwwen loops if ceph df disk usage above percent
GCPCT=25


function ceph_cleanup() {
    echo ">>>>> GC process ..."
    set -x
    time ssh -i ./key/id_rsa $RGWHOST radosgw-admin gc process --include-all &> /tmp/radosgw-admin.log
    set +x
    echo ">>>>> GC complete"
    echo ">>>>> Purge..."
    set -x
    time ssh -i ./key/id_rsa $RGWHOST rados purge default.rgw.data.root --yes-i-really-really-mean-it
    time ssh -i ./key/id_rsa $RGWHOST rados purge default.rgw.buckets.data --yes-i-really-really-mean-it
    time ssh -i ./key/id_rsa $RGWHOST rados purge default.rgw.buckets.index --yes-i-really-really-mean-it
    time ssh -i ./key/id_rsa $RGWHOST rados purge default.rgw.gc --yes-i-really-really-mean-it
    time ssh -i ./key/id_rsa $RGWHOST rados purge default.rgw.log --yes-i-really-really-mean-it
    set +x
    echo ">>>>> Purge settle sleep..."
    sleep 30
    echo ">>>>> Purge complete"
}

function wait_for_cosbench_idle() {
    # wait until cosbench is free to take a workload
    echo ">> Waiting for cosbench to complete the running workload..."
    until [ "$(../../cosbench/cli.sh info 2>/dev/null | grep -c 'Total: 0 active workloads')" -eq 1 ]; do
        echo -n "."
        sleep 2
    done
    echo $'\n>> cosbench ready >>>>>>>'
}


########
# MAIN #
########
if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
    echo "missing  paramis: template filename, bktbegin, bktinc"
    exit 1
fi
TN=$1
ITBEGIN01=$2
ITINC01=$3

echo -e "\nChecking that the RGW host at IP: $RGWHOST"
echo -e "is accessible vis ssh to call radosgw-admin gc process...\n"
ssh -i ./key/id_rsa $RGWHOST radosgw-admin --version
echo -e "\b"
read -p "If the Ceph version is shown, press <Enter> to continue"
echo -e "\b\n"

echo ">> Running with template: $TN"
AN=$(echo -n "/tmp/$TN" | sed 's/__template.xml/__auto.xml/')
echo ">>              auto xml: $AN"
echo -e "\n"
#exit 1;

wait_for_cosbench_idle
PF=$(ssh -i ./key/id_rsa $RGWHOST ceph df | grep -A 1 SIZE | tail -1 | awk '{ print $4 }' | cut -d . -f 1)
echo ">> Checing GC - percent full= $PF %"
if [[ $PF -ge $GCPCT ]]; then
    ceph_cleanup
fi

WCNT=1
while [ true ]; do
    echo $'\n----------------------------------------'

    if [[ $ITINC01 -eq 0 ]]; then
        ITEND01=$ITBEGIN01;
    else
        ITEND01=$(( ITBEGIN01 + ITINC01 - 1 ))
    fi
    echo ">> Preparing workload #$WCNT :"
    echo "   ITBEGIN01=$ITBEGIN01 , ITEND01=$ITEND01"
    echo -n "   cp "
    cp -v "$TN" "$AN"
    sed --in-place "s/#ITBEGIN01#/$ITBEGIN01/g" "$AN"
    sed --in-place "s/#ITEND01#/$ITEND01/g" "$AN"
    #exit 1

    echo ""
    date
    #sleep 30
    ../../cosbench/cli.sh submit "$AN" 2>/dev/null
    echo ""
    wait_for_cosbench_idle

    # check if should purge (if objects names are incrementing)
    if [[ $ITINC01 -ne 0  ]]; then
        PF=$(ssh -i ./key/id_rsa $RGWHOST ceph df | grep -A 1 SIZE | tail -1 | awk '{ print $4 }' | cut -d . -f 1)
        echo ">> Checing GC - percent full= $PF %"
        #exit 1
        if [[ $PF -ge $GCPCT ]]; then
            ceph_cleanup
            sleep 30
        fi
    fi

    ITBEGIN01=$((ITBEGIN01+ITINC01))
    WCNT=$((WCNT+1))

    #exit 1
done

exit 0
