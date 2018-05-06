## cbauto ##
COSBench automation

### Description: ###
The cbauto utility automates submitting workloads to [COSBench](https://github.com/intel-cloud/cosbench)
in an infinite loop with the intention of stress testing Ceph storage performance/memory usage.

Fwatures
* Monitor the storage `%RAW USED` and perform a gc & purge to free space.


### Pre-requisites: ###
Testest with [COSBench version v0.4.2 release candidate 4](https://github.com/intel-cloud/cosbench/releases/tag/v0.4.2.c4)

COSBench must be started before cbauto is run (`start-all.sh`)

cbauto looks for COSBbench installation at `../../cosbench` directory :\
`#  ls -l ../../cosbench`\
`lrwxrwxrwx. 1 root root 8 Feb 22 10:51 ../../cosbench -> 0.4.2.c4`


### Usage: ###
Radosgw host and ssh key nned to be provided 
evironment vars:
`RGWHOST` to the/a host that is running radosgw
example: `export RGWHOST=b08-h31-1029p`

ssh key:
create a link `id_rsa` ssh key which was ssh-copy-id to the RGWHOST

comamnd line parameters

### Examples: ####
