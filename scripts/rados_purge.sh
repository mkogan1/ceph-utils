#!/bin/bash -x

rados purge default.rgw.data.root --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.index --yes-i-really-really-mean-it &
rados purge default.rgw.buckets.data --yes-i-really-really-mean-it &

