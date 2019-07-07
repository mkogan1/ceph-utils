#!/bin/bash

count=50

for s in $(seq 100) ; do
    echo "starting attempt $s"

    #echo stopping previous cluster
    #../src/stop.sh

    #echo starting cluster
    #OSD=5 MON=1 MDS=0 MGR=0 RGW=1 ../src/vstart.sh -n -d -l --short 

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
    s3cmd -c ~/.s3cfg.dectris ls

    b=$(s3cmd -c ~/.s3cfg.dectris ls | wc -l)
    if [ "$b" -gt 0 ] ;then
	break
    fi

    echo "$(date) attempt $s complete"
done

echo "$(date) done"
../src/stop.sh
