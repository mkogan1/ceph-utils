#!/bin/bash

# pre-req fro action.py: 
# pip install --user boto3

setenforce 0
echo mq-deadline > /sys/block/nvme0n1/queue/scheduler

pkill -f action.py
rm /tmp/out-*


count=50
#count=150

for s in $(seq 100) ; do
    echo "starting attempt $s"

    echo stopping previous cluster
    pkill -9 radosgw
    # kill log tails, etc....
    kill $(ps -ef | grep radosgw | grep 8000 | awk '{ print $2 }') 2>/dev/null
    kill $(ps -ef | grep radosgw | grep 8001 | awk '{ print $2 }') 2>/dev/null
    kill $(ps -ef | grep radosgw | grep 8002 | awk '{ print $2 }') 2>/dev/null
    ../src/mstop.sh c1
    ../src/mstop.sh c2
    sleep 2

    set -x
    echo starting cluster
    ###  ZONE 1  ###
    #OSD=5 MON=1 MDS=0 MGR=0 RGW=1 ../src/vstart.sh -n -d -l --short 
    MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c1 -n --nolockdep --bluestore --short -o "bluestore_block_size=536870912000"
    #MON=3 OSD=1 MDS=0 MGR=0 RGW=1 ../src/mstart.sh c1 -n --bluestore --short -o "bluestore_block_size=536870912000"
    ../src/mrun c1 radosgw-admin realm create --rgw-realm=gold --default
    ../src/mrun c1 radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://localhost:8000 --master --default
    ../src/mrun c1 radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east --endpoints=http://localhost:8000 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --master --default
    ../src/mrun c1 radosgw-admin user create --uid=realm.admin --display-name=RealmAdmin --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --system
    ../src/mrun c1 radosgw-admin period update --commit
    # action.py reproducer user
    ../src/mrun c1 radosgw-admin user create --display-name="Test Id" --uid=testid --access-key "0555b35654ad1656d804" --secret "h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=="
    ../src/mrun c1 radosgw-admin user modify --uid=testid --max-buckets=0
    # restart radosgw
    kill $(ps -ef | grep radosgw | grep 8000 | awk '{ print $2 }')
    kill $(ps -ef | grep radosgw | grep 8001 | awk '{ print $2 }')
    ../src/mrgw.sh c1 8000 --debug-rgw=20 --debug-ms=0 --debug_rgw_sync=0 --rgw-zone=us-east --rgw_thread_pool_size=2048

    ps -ef | grep "[r]adosgw" 
    ../src/mrun c1 ceph status
    ../src/mrun c1 ceph df


    ###  ZONE 2  ###
    MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c2 -n --nolockdep --bluestore --short -o "bluestore_block_size=536870912000"
    #MON=3 OSD=1 MDS=0 MGR=0 RGW=1 ../src/mstart.sh c2 -n --bluestore --short -o "bluestore_block_size=536870912000"
    ../src/mrun c2 radosgw-admin realm pull --url=http://localhost:8000 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --default
    ../src/mrun c2 radosgw-admin period pull --url=http://localhost:8000 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --default
    ../src/mrun c2 radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-west  --endpoints=http://localhost:8001 --access-key=a2345678901234567890 --secret=a234567890123456789012345678901234567890 --default
    ../src/mrun c2 radosgw-admin period update --commit
    # restart radosgw
    kill $(ps -ef | grep radosgw | grep 8001 | awk '{ print $2 }')
    kill $(ps -ef | grep radosgw | grep 8002 | awk '{ print $2 }')
    ../src/mrgw.sh c2 8001 --debug-rgw=5 --debug-ms=0 --debug_rgw_sync=0 --rgw-zone=us-west --rgw_thread_pool_size=2048

    ps -ef | grep "[r]adosgw" 
    ../src/mrun c2 ceph status
    ../src/mrun c2 ceph df

    sleep 4
    ../src/mrun c2 radosgw-admin sync status


    #exit 1
    #set +x


    d=$(dirname $0)

    # dd if=/dev/urandom of=/tmp/samplefile1 bs=1M count=300
    # dd if=/dev/urandom of=/tmp/samplefile2 bs=1M count=350

    echo "Hello" > /tmp/samplefile1
    echo "World" > /tmp/samplefile2

    echo starting $count jobs
    for count in $(seq $count) ; do
	  python $d/action.py > "/tmp/out-$$-$count"&
    done

    echo "$(date) listing jobs"
    jobs

    echo "$(date) waiting for $count jobs to complete"
    wait

    echo "$(date) listing remaining jobs"
    jobs

    # echo stopping cluster
    # ../src/stop.sh

    echo "$(date) listing buckets"
    s3cmd ls

    b=$(s3cmd ls | wc -l)
    if [ "$b" -gt 0 ] ;then
      #break
      echo "!!! REPRODUCED , EXIT !!!"
      exit 1
    fi

    echo "$(date) attempt $s complete"

    exit 1
done

echo "$(date) done"
../src/stop.sh
