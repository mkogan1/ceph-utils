#!/usr/bin/env bash
# Tip: run with "$0 | column -t" or
#                $0 "" "default.rgw.buckets.non-ec" | column -t
# Refrences: http://ceph.com/geen-categorie/get-omap-keyvalue-size/
#            http://cephnotes.ksperis.com/blog/2015/06/25/get-omap-key-slash-value-size

CEPH_DIR=${1:-"./bin"}
if [  -f "${CEPH_DIR}/rados" ]; then
    CEPH_DIR="${CEPH_DIR}/"
else
	CEPH_DIR=""
fi

pool=${2:-"default.rgw.buckets.index"}
list=`${CEPH_DIR}rados -p $pool ls 2>/dev/null`

echo "pool=$pool"
echo "object size_keys(kB) size_values(kB) total(kB) nr_keys nr_values"
for obj in $list; do
    RES=$(${CEPH_DIR}rados -p $pool listomapvals $obj 2>/dev/null | awk '
    /^value \(.* bytes\)/ { sizevalues+= substr($2, 2, length($2)); nbvalues++ }
    END { printf("%i %i\n", sizevalues, nbvalues) }
    ')
    SIZEVALUES=$(echo $RES | cut -f1 -d' ')
    NUMVALUES=$(echo $RES | cut -f2 -d' ')

    RES=$(${CEPH_DIR}rados -p $pool listomapkeys $obj 2>/dev/null | awk '
    { sizekeys+=length(); nbkeys++ }
    END { printf("%i %i\n", sizekeys, nbkeys) }
    ')
    SIZEKEYS=$(echo $RES | cut -f1 -d' ')
    NUMKEYS=$(echo $RES | cut -f2 -d' ')

    echo -e "${obj} $((SIZEKEYS/1024)) $((SIZEVALUES/1024)) $(( (SIZEKEYS+SIZEVALUES)/1024 )) ${NUMKEYS} ${NUMVALUES}"
done
