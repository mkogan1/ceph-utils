set -x

# pre-req:
# pip install awscli
# aws configure

#CHANCE=2
#CHANCE=4
CHANCE=65536

#BKT=rXedhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef
BKT=redhat_testing_bucket_$(uuidgen)

#EPURL=http://localhost:8000
EPURL=http://172.16.0.6:8000

mkdir ~/tmp/
#dd if=/dev/urandom of=~/tmp/100MB-rand.dat bs=1M count=100
#INITIAL_FILE=~/tmp/100MB-rand.dat
#fallocate -l 500M ~/tmp/500MB-zero.dat
#INITIAL_FILE=~/tmp/500MB-zero.dat
#fallocate -l 100M ~/tmp/100MB-zero.dat
#INITIAL_FILE=~/tmp/100MB-zero.dat
#fallocate -l 4K ~/tmp/4K-zero.dat
#INITIAL_FILE=~/tmp/4K-zero.dat

while true; do
  #INITIAL_FILE=~/tmp/128M.dat
  #dd if=/dev/urandom of=${INITIAL_FILE} bs=1M count=128
  INITIAL_FILE=~/tmp/rand_size.dat
  dd if=/dev/urandom of=${INITIAL_FILE} bs=1M count=$(( RANDOM % 128 ))

  ### - create bucket
  aws --endpoint-url ${EPURL} s3 mb s3://${BKT}

  # flags ref: https://bugzilla.redhat.com/show_bug.cgi?id=1658308#c6
  radosgw-admin bucket list
  radosgw-admin metadata get bucket.instance:${BKT}:$(radosgw-admin metadata get bucket:${BKT} 2>/dev/null | jq -r ".data.bucket.bucket_id") 2>/dev/null | jq . | egrep "flags|ver"

  ### - enable versioning on the bucket
  aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Enabled

  aws --endpoint-url ${EPURL} s3api get-bucket-versioning --bucket ${BKT}
  radosgw-admin metadata get bucket.instance:${BKT}:$(radosgw-admin metadata get bucket:${BKT} 2>/dev/null | jq -r ".data.bucket.bucket_id") 2>/dev/null | jq . | egrep "flags|ver"

  ### - Upload initial_file.txt
  if [[ $(( RANDOM % ${CHANCE} )) -eq 0 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 cp ${INITIAL_FILE} s3://${BKT}/initial_file.txt

  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human

  ### - Upload new version of initial_file.txt
  if [[ $(( RANDOM % ${CHANCE} )) -eq 0 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Suspended ; fi
  dd if=/dev/urandom of=${INITIAL_FILE} bs=1M count=$(( RANDOM % 128 ))
  aws --endpoint-url ${EPURL} s3 cp ${INITIAL_FILE} s3://${BKT}/initial_file.txt

  aws --endpoint-url ${EPURL} s3api list-object-versions --bucket ${BKT} --prefix initial_file.txt

  ### - Delete initial_file.txt
  if [[ $(( RANDOM % ${CHANCE} )) -eq 0 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human
  ###!!!  will stop syncing obj if versioning is suspended
  aws --endpoint-url ${EPURL} s3 rm s3://${BKT}/initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human

  ### - Upload v2_initial_file.txt
  if [[ $(( RANDOM % ${CHANCE} )) -eq 0 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Suspended ; fi
  dd if=/dev/urandom of=${INITIAL_FILE} bs=1M count=$(( RANDOM % 128 ))
  aws --endpoint-url ${EPURL} s3 cp ${INITIAL_FILE} s3://${BKT}/v2_initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human

  ### - Delete v2_initial_file.txt
  if [[ $(( RANDOM % ${CHANCE} )) -eq 0 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket ${BKT} --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human
  aws --endpoint-url ${EPURL} s3 rm s3://${BKT}/v2_initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls ${BKT} --human


  ### Customer is attempting to remove bucket with following command:
  radosgw-admin bucket list
  radosgw-admin bucket stats --bucket ${BKT}
  # comment to increase ver count
  #radosgw-admin bucket rm --bucket=${BKT} --purge-objects
  #radosgw-admin bucket stats --bucket ${BKT}

done


