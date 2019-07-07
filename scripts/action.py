#!/usr/bin/env python 

import boto3
import logging
import sys
import uuid
import os
import time

count=50

def enable_bucket_versioning(self, bucket_name):
    response = requests.put(
        self.base_url + bucket_name + "/?versioning", data={"Status": "Enabled"}
    )

def delete_bucket_content(s3_client, bucket_name):
    objects = s3_client.list_object_versions(Bucket=bucket_name)

    all_objects = objects.get("Versions", []) + objects.get("DeleteMarkers", [])

    s3_client.delete_objects(
        Bucket=bucket_name,
        Delete={
            "Quiet": True,
            "Objects": [
                {"Key": obj["Key"], "VersionId": obj["VersionId"]}
                for obj in all_objects
            ],
        },
    )

# default endpoint from vstart
endpoint='http://127.0.0.1:8000'
# if len(sys.argv) > 2:
#     endpoint=sys.argv[2]

# keys from vstart
access_key='0555b35654ad1656d804'
secret_key='h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=='


def do_stuff(s3, client):
    bucket_name = "testing-bucket-" + str(uuid.uuid1())
    bucket = s3.Bucket(bucket_name)
    while True:
        try:
            bucket.create()
            break
        except:
            print "failed to create bucket {}, trying again.".format(bucket_name)

    bucket.Versioning().enable()

    try:
        bucket.upload_file("/tmp/samplefile1", "file1")
        bucket.upload_file("/tmp/samplefile2", "file1")

        s3.Object(bucket_name,'file2').copy_from(CopySource='%s/%s' % (bucket_name, 'file1'))
        s3.Object(bucket_name, 'file1').delete()

        s3.Object(bucket_name,'file1').copy_from(CopySource='%s/%s' % (bucket_name, 'file2'))
        s3.Object(bucket_name, 'file2').delete()
    except:
        print "got error while manipulating bucket {}".format(bucket_name)

    # objs = client.list_object_versions(Bucket=bucket_name)
    # print objs

    while True:
        try:
            delete_bucket_content(client, bucket_name)
            break
        except:
            print "failed to delete contents of bucket {}, trying again".format(bucket_name)

    while True:
        try:
            bucket.delete()
            break
        except:
            print "failed to delete bucket {}, trying again".format(bucket_name)

    bucket.wait_until_not_exists()


s3 = boto3.resource('s3',
                    endpoint_url=endpoint,
                    aws_access_key_id=access_key,
                    aws_secret_access_key=secret_key)

client = boto3.client('s3',
                      endpoint_url=endpoint,
                      aws_access_key_id=access_key,
                      aws_secret_access_key=secret_key)

for x in range(count):
    print ("{}: pid {} doing count {}".format(time.strftime("%H:%M:%S"), os.getpid(), x))
    sys.stdout.flush()
    do_stuff(s3, client)
    sys.stdout.flush()

print ("{}: pid {} is done".format(time.strftime("%H:%M:%S"), os.getpid()))
