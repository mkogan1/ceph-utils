#!/bin/bash
for bucket in `./bin/radosgw-admin metadata list bucket 2>/dev/null | jq -r '.[]' | sort`
do
   actual_id=`./bin/radosgw-admin bucket stats --bucket=${bucket} 2>/dev/null | jq -r '.id'`
   for instance in `./bin/radosgw-admin metadata list bucket.instance 2>/dev/null | jq -r '.[]' | grep ${bucket}: | cut -d ':' -f 2`
   do
     if [ "$actual_id" != "$instance" ]
     then
       echo "# ./bin/radosgw-admin bi purge --bucket=${bucket} --bucket-id=${instance}"
       #./bin/radosgw-admin bi purge --bucket=${bucket} --bucket-id=${instance}
       #./bin/radosgw-admin metadata rm bucket.instance:${bucket}:${instance}
     fi
   done
done
