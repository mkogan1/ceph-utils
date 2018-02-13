#!/bin/bash -x

if [ -f ./bin/radosgw-admin ]; then
        BINP="./bin/"
else
	BINP=""
fi


${BINP}ceph pg set_full_ratio 0.99
sleep 1

${BINP}rados purge default.rgw.data.root --yes-i-really-really-mean-it &
${BINP}rados purge default.rgw.buckets.data --yes-i-really-really-mean-it &
${BINP}rados purge default.rgw.buckets.index --yes-i-really-really-mean-it &
#${BINP}rados purge default.rgw.meta --yes-i-really-really-mean-it &
#${BINP}rados purge default.rgw.users.uid --yes-i-really-really-mean-it &
#${BINP}rados purge default.rgw.users.swift --yes-i-really-really-mean-it &

sleep 2
${BINP}rados purge default.rgw.gc --yes-i-really-really-mean-it
${BINP}rados purge default.rgw.log --yes-i-really-really-mean-it

${BINP}ceph pg set_full_ratio 0.95

echo "waiting for completion..."
wait


