#!/bin/bash -x
ceph pg set_full_ratio 0.99

rados purge default.rgw.data.root --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.data --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.index --yes-i-really-really-mean-it &
rados purge default.rgw.meta --yes-i-really-really-mean-it &
rados purge default.rgw.users.uid --yes-i-really-really-mean-it &
rados purge default.rgw.users.swift --yes-i-really-really-mean-it &

sleep 2
rados purge default.rgw.gc --yes-i-really-really-mean-it
rados purge default.rgw.log --yes-i-really-really-mean-it

ceph pg set_full_ratio 0.95

echo "waitingi for completion..."
wait

