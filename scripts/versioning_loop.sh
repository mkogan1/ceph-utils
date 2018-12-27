set -x

# pre-req:
# pip install awscli
# aws configure

#EPURL=http://localhost:8000
EPURL=http://172.16.0.6:8000

while true; do

  ### - create bucket
  aws --endpoint-url ${EPURL} s3 mb s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef

  # flags ref: https://bugzilla.redhat.com/show_bug.cgi?id=1658308#c6
  radosgw-admin bucket list
  radosgw-admin metadata get bucket.instance:redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef:$(radosgw-admin metadata get  bucket:redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef 2>/dev/null | jq -r ".data.bucket.bucket_id") 2>/dev/null | jq . | egrep "flags|ver"

  ### - enable versioning on the bucket
  aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Enabled

  aws --endpoint-url ${EPURL} s3api get-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef
  radosgw-admin metadata get bucket.instance:redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef:$(radosgw-admin metadata get  bucket:redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef 2>/dev/null | jq -r ".data.bucket.bucket_id") 2>/dev/null | jq . | egrep "flags|ver"

  ### - Upload initial_file.txt
  if [[ $(( RANDOM % 2 )) -eq 1 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 cp ~/tmp/100MB-rand.dat s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef/initial_file.txt

  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human

  ### - Upload new version of initial_file.txt
  if [[ $(( RANDOM % 2 )) -eq 1 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 cp ~/tmp/100MB-rand.dat s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef/initial_file.txt

  aws --endpoint-url ${EPURL} s3api list-object-versions --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --prefix initial_file.txt

  ### - Delete initial_file.txt
  if [[ $(( RANDOM % 2 )) -eq 1 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human
  aws --endpoint-url ${EPURL} s3 rm s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef/initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human

  ### - Upload v2_initial_file.txt
  if [[ $(( RANDOM % 2 )) -eq 1 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 cp ~/tmp/100MB-rand.dat s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef/v2_initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human

  ### - Delete v2_initial_file.txt
  if [[ $(( RANDOM % 2 )) -eq 1 ]]; then aws --endpoint-url ${EPURL} s3api put-bucket-versioning --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --versioning-configuration Status=Suspended ; fi
  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human
  aws --endpoint-url ${EPURL} s3 rm s3://redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef/v2_initial_file.txt
  aws --endpoint-url ${EPURL} s3 ls redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --human


  ### Customer is attempting to remove bucket with following command:
  radosgw-admin bucket list
  radosgw-admin bucket stats --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef
  # comment to increase ver count
  #radosgw-admin bucket rm --bucket=redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef --purge-objects
  #radosgw-admin bucket stats --bucket redhat_testing_bucket_bea48dac-e74a-11e8-8d41-f85971b8e3ef

done
