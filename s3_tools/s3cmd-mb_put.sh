#!/bin/bash -x

if [[ "$#" -ne 1 ]]; then
    BUS=$1; BUE=$2
else
    BUS=1; BUE=490
fi

#for bu in {1..490}; do
#for bu in {491..500}; do
for ((bu=BUS; bu <= BUE; bu++)); do
    #BUCKETC=`dd if=/dev/urandom bs=1 count=4 | hexdump -e '16/1 "%02x"'| sed -e 's/[[:space:]]*$//'` 2>/dev/null
    BUCKETC=$(printf "%05d" $bu)
    s3cmd mb "s3://rhbucket.$BUCKETC"
    if [ $? -ne 0 ]; then exit 1; fi
    for i in {1..2}; do
        dd if=/dev/urandom of=/tmp/devrand.dat bs=1k count=1
        RANDC=`dd if=/dev/urandom bs=1 count=4 | hexdump -e '16/1 "%02x"'| sed -e 's/[[:space:]]*$//'` 2>/dev/null
        s3cmd put "/tmp/devrand.dat" "s3://rhbucket.$BUCKETC/devrand.$RANDC"
        #sleep 1
    done
done
