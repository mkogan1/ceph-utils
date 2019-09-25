import os
import sys
import threading
import boto


import boto.s3.connection
import random
import time
import multiprocessing

access_key = 'b2345678901234567890'
secret_key = 'b234567890123456789012345678901234567890'

conn = boto.connect_s3(
        aws_access_key_id = access_key,
        aws_secret_access_key = secret_key,
        host = 'localhost', port = 8000 ,
        is_secure=False,               # uncomment if you are not using ssl
        calling_format = boto.s3.connection.OrdinaryCallingFormat(),
        )

my_8mb = str(bytearray(1024*1024*8))
my_5mb = str(bytearray(1024*1024*5))
my_10mb = str(bytearray(1024*1024*10))
my_1mb = str(bytearray(1024*1024*1))
my_4mb = str(bytearray(1024*1024*4))
my_4k = str(bytearray(1024*4))
my_1k = str(bytearray(1024*1))

array_of_obj =  [  my_4k , my_4k , my_4k ]

my_bucket_name = 'tpcds2'
conn.create_bucket( my_bucket_name )
bucket = conn.get_bucket( my_bucket_name )


def worker_write_with_directory(dir_name,num_of_obj):
    """thread worker_write function"""

    part = chr(random.randint(65,65+25)) # used for partitioning  

    for x in range(num_of_obj):
        #print "iter=",iter
        st = time.time()
        new_key =  "{}file-meta-{}-{}-{}".format( dir_name , threading.current_thread().ident , x , part )
        k1 = bucket.new_key( new_key );
        obj_to_load = array_of_obj[ random.randint(0,2) ]
        k1.set_contents_from_string( obj_to_load );
        total = time.time() - st
        print "load {} bytes in {} sec ; {} mb/s".format( len(obj_to_load) , total ,round( (len(obj_to_load)/total)/(1024*1024) , 7) )
    print "done worker_write thread-{} process-{}".format(threading.current_thread().ident , os.getpid())       

############################## main ###############################


if len(sys.argv)<3:
	print "num_of_parallel , obj_per_thread , object_size(1k,4k,1m,4m)"
	sys.exit(0);

num_of_thread = sys.argv[1]
obj_per_thread = sys.argv[2]
object_size = sys.argv[3]

if (len(sys.argv) == 6):
	dir_size = sys.argv[5]

threads = []

if (object_size == '1k' ):
	array_of_obj =  [  my_1k , my_1k , my_1k ]
if (object_size == '1m' ):
	array_of_obj =  [  my_1mb , my_1mb , my_1mb ]
if (object_size == '4m' ):
	array_of_obj =  [  my_4mb , my_4mb , my_4mb ]
if (object_size == '4k' ):
	array_of_obj =  [  my_4k , my_4k , my_4k ]

def wait_for_all():
    for thr in threads:
        thr.join()
        print "thr=",thr
        print "done"

def wait_for_all_process():
    for p in jobs:
        p.join()
        print "process=",p
        print "complete"


def boot_process_write_in_directory():
    for i in range( 0, int(num_of_thread) ):
        dir_name = "/dir-name-{}/".format(i)
        p = multiprocessing.Process(target=worker_write_with_directory,args=[ dir_name , int(obj_per_thread) ])
        jobs.append(p)
        p.start()
    print "boot all process"

def boot_thread_write_with_directory():
    for i in range( 0, int(num_of_thread) ):
        dir_name = "/dir-name-{}/".format(i)
        t = threading.Thread(target=worker_write_with_directory,args=[ dir_name , int(obj_per_thread) ])
        threads.append(t)
        t.start()
    print "boot all threads"



#boot_process_write_in_directory()
#wait_for_all_process()

boot_thread_write_with_directory()
wait_for_all()


