#!/bin/bash 
set -x
while true; do
  #TC=$(s3cmd ls -r --human s3://hadoop01 | grep attempt | grep part | wc -l)
  TC=$(s3cmd ls -r --human s3://hadoop01 | grep attempt | grep part | grep $1 | wc -l)
  date
  echo "TC=$TC"
  if [ "$TC" -gt 0 ]; then 
    #sleep 1
    ps -ef | grep "[m]apreduce" | grep -v bash | awk '{ print $2 }' | xargs --verbose kill -9
    sleep 5
    ps -ef | grep "[m]apreduce" | grep -v bash | awk '{ print $2 }' | xargs --verbose kill -9

    #hadoop job -kill $2

    exit
  fi
  sleep 1
done


