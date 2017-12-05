#!/bin/bash -x

rados purge default.rgw.data.root --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.data --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.index --yes-i-really-really-mean-it &
rados purge default.rgw.meta --yes-i-really-really-mean-it &
rados purge default.rgw.users.uid --yes-i-really-really-mean-it &
rados purge default.rgw.gc --yes-i-really-really-mean-it &
rados purge default.rgw.log --yes-i-really-really-mean-it &

sleep 2
echo "waitingi for completion..."
wait

