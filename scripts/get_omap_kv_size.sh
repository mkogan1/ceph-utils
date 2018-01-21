#!/usr/bin/env bash
# Tip: run with "$0 | column -t"
# REfrences: http://ceph.com/geen-categorie/get-omap-keyvalue-size/
#            http://cephnotes.ksperis.com/blog/2015/06/25/get-omap-key-slash-value-sizeA

CEPH_DIR=${1:-"./bin"}
if [  -f "${CEPH_DIR}/rados" ]; then
    CEPH_DIR="${CEPH_DIR}/"
else
	CEPH_DIR=""
fi

pool=${2:-"default.rgw.buckets.index"}
list=`${CEPH_DIR}rados -p $pool ls`

echo "object size_keys(kB) size_values(kB) total(kB) nr_keys nr_values"
for obj in $list; do
    RES=$(${CEPH_DIR}rados -p $pool listomapvals $obj | awk '
    /^value \(.* bytes\)/ { sizevalues+= substr($2, 2, length($2)); nbvalues++ }
    END { printf("%i %i\n", sizevalues, nbvalues) }
    ')
    SIZEVALUES=$(echo $RES | cut -f1 -d' ')
    NUMVALUES=$(echo $RES | cut -f2 -d' ')

    RES=$(${CEPH_DIR}rados -p $pool listomapkeys $obj | awk '
    { sizekeys+=length(); nbkeys++ }
    END { printf("%i %i\n", sizekeys, nbkeys) }
    ')
    SIZEKEYS=$(echo $RES | cut -f1 -d' ')
    NUMKEYS=$(echo $RES | cut -f2 -d' ')

    echo -e "${obj} $((SIZEKEYS/1024)) $((SIZEVALUES/1024)) $(( (SIZEKEYS+SIZEVALUES)/1024 )) ${NUMKEYS} ${NUMVALUES}"
done
