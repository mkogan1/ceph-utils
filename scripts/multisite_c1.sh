#!/bin/bash

../src/mstop.sh c1
kill --verbose -9 $(ps -ef | grep 'bin\/radosgw' | grep "8001" | awk '{ print $2 }')
echo "----------------------------------------------"
ps -ef | grep --color '[r]adosgw'
echo "----------------------------------------------"
ps -ef | grep --color '[c]eph'
echo "----------------------------------------------"
read -p "Press [enter] to continue"


MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c1 -n --bluestore -o bluestore_block_size=536870912000 -o rgw_dynamic_resharding=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups
##-- ALT [1] --##
#MON=3 OSD=1 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c1 -n --bluestore -o bluestore_block_size=536870912000 -o rgw_dynamic_resharding=false -o rgw_cache_enabled=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups
##-- ALT [2] (filestore) --##
#MON=3 OSD=3 MDS=0 MGR=1 RGW=1 ../src/mstart.sh c1 -n -f -o rgw_dynamic_resharding=false -o rgw_cache_enabled=false -o rgw_cache_expiry_interval=0 | ccze -A -onolookups

../src/mrun c1 radosgw-admin realm create --rgw-realm=gold --default | jq

../src/mrun c1 radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://localhost:8001 --master --default | jq

../src/mrun c1 radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east --endpoints=http://localhost:8001 --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --master --default | jq

../src/mrun c1 radosgw-admin user create --uid=realm.admin --display-name=RealmAdmin --access-key a2345678901234567890 --secret a234567890123456789012345678901234567890 --system | jq

#../src/mrun c1 radosgw-admin zone placement modify --rgw-zone=us-east --placement-id=default-placement --compression=zstd | jq

../src/mrun c1 radosgw-admin period update --commit | jq

# cosbench user
../src/mrun c1 radosgw-admin user create --display-name="Test Id" --uid=testid --access-key b2345678901234567890 --secret b234567890123456789012345678901234567890 | jq

../src/mrun c1 radosgw-admin user modify --uid=testid --max-buckets=0 | jq


echo "----------------------------------------------"
# restart radosgw
#kill $(ps -ef | grep radosgw | grep 8001 | awk '{ print $2 }')
#../src/mrgw.sh c1 8001 --debug-rgw=20 --debug-ms=1 --rgw-zone=us-east
../src/mrgw.sh c1 8001 --debug-rgw=20 --debug-ms=0 --debug_rgw_sync=20 --rgw-zone=us-east


echo "----------------------------------------------"
ps -ef | grep --color "[r]adosgw" 
echo "----------------------------------------------"
../src/mrun c1 ceph -s | ccze -A -onolookups
../src/mrun c1 ceph df | ccze -A -onolookups

