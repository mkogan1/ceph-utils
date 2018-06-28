#! /usr/bin/python
import json
import subprocess
import os.path
'''
The script purpose is to monitor Ceph RGW capacity Usage
The script track after quota of users, usage capacity etc.
'''

quotas = list() # list of all quotas
sum_in_kb_of_quotas = 0 # the size of all quotas
sum_of_unlimited_users = 0 # number of users without quota
sum_of_not_limited_kb = 0 # capacity usage by users without quota
sum_of_not_limited_kb_notrounded = 0 # capacity usage by users without quota not rounded
sum_of_limited_kb = 0 # capacity usage by users with quota
sum_of_limited_kb_notrounded = 0 # capacity usage by users with quota not rounded
sum_of_all_kb = 0 # capacity usage by all users
sum_of_limited_users = 0 # number of users with quota
sum_of_all_users = 0 # number of all users

'''
This method add escape character(\) to the user name for users contains $ and \
'''
def parseuser(user_to_parse):
    user_to_parse = str(user_to_parse).replace("$", "\$")
    user_to_parse = str(user_to_parse).replace("/", "\/")
    return user_to_parse

'''
This method runs a subprocess with constatnt parameters
'''
def run_cmd(cmd):
    ceph_path = ""
    if os.path.exists("./bin/ceph"):
        ceph_path = "./bin/"
    return json.loads(subprocess.check_output(ceph_path+cmd,shell=True).decode("UTF-8"))


users_json = run_cmd("radosgw-admin metadata list user") # command to get all users of rgw
for user in users_json:
    user = parseuser(user)
    print("#DEBUG# user=", user)
    quotas.append(run_cmd("radosgw-admin user info --uid=\"" + str(user) + "\"")) #check quota detail of user
    sum_of_all_users += 1

for quota in quotas:

    if int(quota['user_quota']['max_size_kb']) == -1: #user do not have quota
        sum_of_unlimited_users +=1
        user_id = quota['user_id']
        user_id = parseuser(user_id)
        print("#DEBUG# user_id=", user_id)
        used_size = run_cmd("radosgw-admin user stats --sync-stats --uid=\"" + str(user_id) + "\"") # user usage detail
        sum_of_not_limited_kb += (int(used_size['stats']['total_bytes_rounded']) / 1024) # used size in kb
        sum_of_not_limited_kb_notrounded += (int(used_size['stats']['total_bytes']) / 1024) # used size in kb
        #print("#DEBUG# sum_of_not_limited_kb=", sum_of_not_limited_kb) 
    else:
        sum_in_kb_of_quotas += int(quota['user_quota']['max_size_kb']) # user have quota
        user_id = quota['user_id']
        user_id = parseuser(user_id)
        print("#DEBUG# user_id=", user_id)
        used_size = run_cmd("radosgw-admin user stats --sync-stats --uid=\"" + str(user_id) + "\"") # user usage detail
        sum_of_limited_kb += (int(used_size['stats']['total_bytes_rounded']) / 1024) # used size in kb
        sum_of_limited_kb_notrounded += (int(used_size['stats']['total_bytes']) / 1024) # used size in kb
        #print("#DEBUG# sum_of_limited_kb=", sum_of_limited_kb, "user_id=", user_id) 

sum_of_all_kb = sum_of_limited_kb + sum_of_not_limited_kb
sum_of_all_kb_notrounded = sum_of_limited_kb_notrounded + sum_of_not_limited_kb_notrounded

print '\n'
print("#DEBUG# sum_of_all_kb=", sum_of_all_kb, " sum_of_all_kb_notrounded=", sum_of_all_kb_notrounded, " sum of all (rounded - not rounded)KB =", sum_of_all_kb-sum_of_all_kb_notrounded)
print '\n'

sum_of_limited_users = sum_of_all_users - sum_of_unlimited_users
print (json.dumps({'sum_of_unlimited_users':int(sum_of_unlimited_users),'sum_in_kb_of_quotas':int(sum_in_kb_of_quotas),'sum_of_not_limited_kb':int(sum_of_not_limited_kb),'sum_of_limited_kb':int(sum_of_limited_kb),'sum_of_all_kb':int(sum_of_all_kb),'sum_of_limited_users':int(sum_of_limited_users),'sum_of_all_users':int(sum_of_all_users)}))

