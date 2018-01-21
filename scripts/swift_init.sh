#!/bin/bash -x

CEPH_DIR=${1:-"./bin"}
if [ -f "$CEPH_DIR/radosgw-admin" ]; then
	RA="$CEPH_DIR/radosgw-admin"
else
	RA=radosgw-admin
fi
$RA user create --uid="cosbench" --display-name="cosbench" | jq
$RA user modify --uid=cosbench --max-buckets=0 | jq
$RA subuser create --uid=cosbench --subuser=cosbench:operator --secret=redhat --access=full --key-type=swift | jq
