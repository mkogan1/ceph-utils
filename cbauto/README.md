## cbauto ##
COSBench automation

### Description: ###
The cbauto utility automates submitting workloads to [COSBench](https://github.com/intel-cloud/cosbench)
in an infinite loop with the intention of stress testing Ceph storage performance/memory usage.

Fwatures
* Monitor the storage `ceph df` `%RAW USED` between iterations and free space if necesary.


### Pre-requisites: ###
Testest with [COSBench version v0.4.2 release candidate 4](https://github.com/intel-cloud/cosbench/releases/tag/v0.4.2.c4)

_COSBench:_
COSBench must be started before cbauto is run (`start-all.sh`)

cbauto looks for COSBbench installation at `../../cosbench` directory:\
`#  ls -l ../../cosbench`\
`lrwxrwxrwx. 1 root root 8 Feb 22 10:51 ../../cosbench -> 0.4.2.c4`

_Rados gateway ssh access:_\
Radosgw host and ssh key need to be provided in order to free storage space automatically:

  + _Evironment vars:_\
`RGWHOST` to the/a host that is running radosgw\
example: `export RGWHOST=b08-h31-1029p`

 + _ssh key:_\
 perform ssh-cppy-id to the RGWHOST or\
 copy `id_rsa` ssh key file from other machine like jumphost which has done ssh-copy-id to the RGWHOST to the `./key` directory

_Ceph user:_\
Create S3 and/or Swift user to be used by the workload.

### Usage: ###

_Template files:_\
The cbauto repo contains several workload sample files.\
In the workload sample file edit the `auth` line and configure the user, password and the radosgw host,\
For example:\
`vim swift-workload_multi_test-small_obj__template.xml`\
`<auth caching="true" type="swauth" config="username=cosbench:operator;password=redhat;auth_url=http://b08-h31-1029p:8080/auth/v1.0" />`

_Comamnd line parameters:_\


_Additional environment vars:_\
export GCPCT to configure the percentage of `%RAW USED` above which to trigger freeing of space.\
Example: `export GCPCT=25`


### Examples: ####
