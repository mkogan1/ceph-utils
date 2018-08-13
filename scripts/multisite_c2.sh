#!/bin/bash

../src/mstop.sh c2
kill --verbose -9 $(ps -ef | grep 'bin\/radosgw' | grep "8002" | awk '{ print $2 }')
echo "----------------------------------------------"
ps -ef | grep --color '[r]adosgw'
echo "----------------------------------------------"
ps -ef | grep --color '[c]eph'
echo "----------------------------------------------"
read -p "Press [enter] to continue"


MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c2 -d -n --bluestore -o bluestore_block_size=536870912000 -o rgw_dynamic_resharding=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups
##-- ALT [1] --##
#MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c2 -d -n --bluestore -o bluestore_block_size=536870912000 -o rgw_dynamic_resharding=false -o rgw_cache_enabled=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups
##-- ALT [2] (filestore) --##
#MON=3 OSD=3 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c2 -n -f -o rgw_dynamic_resharding=false -o rgw_cache_enabled=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups

../src/mrun c2 radosgw-admin realm pull --url=http://localhost:8001 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --default | jq

../src/mrun c2 radosgw-admin period pull --url=http://localhost:8001 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --default | jq

../src/mrun c2 radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-west  --endpoints=http://localhost:8002 --access-key=a2345678901234567890 --secret=a234567890123456789012345678901234567890 --default | jq

#../src/mrun c2 radosgw-admin zone placement modify --rgw-zone=us-west --placement-id=default-placement --compression=zstd | jq

../src/mrun c2 radosgw-admin period update --commit


echo "----------------------------------------------"
# restart radosgw
#kill $(ps -ef | grep radosgw | grep 8002 | awk '{ print $2 }')
#../src/mrgw.sh c2 8002 --debug-rgw=20 --debug-ms=1 --rgw-zone=us-west
../src/mrgw.sh c2 8002 --debug-rgw=20 --debug-ms=0 --debug_rgw_sync=20 --rgw-zone=us-west


echo "----------------------------------------------"
ps -ef | grep --color "[r]adosgw" 
echo "----------------------------------------------"
../src/mrun c1 ceph -s | ccze -A -onolookups
../src/mrun c1 ceph df | ccze -A -onolookups

echo "----------------------------------------------"
sleep 4
../src/mrun c2 radosgw-admin sync status | ccze -A -onolookups

