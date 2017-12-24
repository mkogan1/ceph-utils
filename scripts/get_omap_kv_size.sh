#!/usr/bin/env bash

CEPH_DIR=${1:-"./bin"}

pool=${2:-"default.rgw.buckets.index"}
list=`$CEPH_DIR/rados -p $pool ls`

(
echo "object size_keys(kB) size_values(kB) total(kB) nr_keys nr_values"
for obj in $list; do
    echo -en "$obj ";
    $CEPH_DIR/rados -p $pool listomapvals $obj | awk '
    /^key: \(.* bytes\)/ { sizekey+= substr($2, 2, length($2)); nbkeys++ }
    /^value: \(.* bytes\)/ { sizevalue+= substr($2, 2, length($2)); nbvalues++ }
    END { printf("%i %i %i %i %i\n", sizekey/1024, sizevalue/1024, (sizekey+sizevalue)/1024, nbkey, nbvalues) }
'
done
)
