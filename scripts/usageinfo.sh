#!/bin/bash

#./bin/radosgw-admin caps add --uid=cosbench --caps="users=read, write" | jq
#./bin/radosgw-admin caps add --uid=cosbench --caps="usage=read, write" | jq
#./bin/radosgw-admin caps add --uid=cosbench --caps="buckets=read, write" | jq

token=b2345678901234567890 ## USER_TOKEN
secret=b234567890123456789012345678901234567890 ## USER_SECRET
query=$1
bucket=$2
query3="&uid="
query4="&bucket="
#query2=admin/usage
query2=admin/bucket
#date=$(for i in $(date "+%H") ; do date "+%a, %d %b %Y $(( 10#$i-8 )):%M:%S +0000" ; done)
date=$(date -Ru)
header="GET\n\n\n${date}\n/${query2}"
sig=$(echo -en ${header} | openssl sha1 -hmac ${secret} -binary | base64)
#curl -v -H "Date: ${date}" -H "Authorization: AWS ${token}:${sig}" -L -X GET "http://127.0.0.1:8000/${query2}?format=json${query3}${query}" -H "Host: 127.0.0.1:8000"
curl -v -H "Date: ${date}" -H "Authorization: AWS ${token}:${sig}" -L -X GET "http://127.0.0.1:8000/${query2}?format=json${query3}${query}${query4}${bucket}&stats=true" -H "Host: 127.0.0.1:8000"

