## cbauto ##
COSBench automation

### Description: ###
The cbauto utility automates submitting workloads to [COSBench](https://github.com/intel-cloud/cosbench)
in an infinite loop with the intention of stress testing Ceph storage performance/memory usage.

Fwatures
* Monitor the storage `ceph df` `%RAW USED` between iterations and free space if necesary.


### Pre-requisites: ###
Testest with [COSBench version v0.4.2 release candidate 4](https://github.com/intel-cloud/cosbench/releases/tag/v0.4.2.c4)

COSBench must be started before cbauto is run (`start-all.sh`)

cbauto looks for COSBbench installation at `../../cosbench` directory :\
`#  ls -l ../../cosbench`\
`lrwxrwxrwx. 1 root root 8 Feb 22 10:51 ../../cosbench -> 0.4.2.c4`


### Usage: ###
Radosgw host and ssh key nned to be provided in order to free storage space.
evironment vars:
`RGWHOST` to the/a host that is running radosgw
example: `export RGWHOST=b08-h31-1029p`

ssh key:\
 perform ssh-cppy-id to the RGWHOST or\
 copy `id_rsa` ssh key file from other machine like jumphost which has done ssh-copy-id to the RGWHOST to the `./key` directory

comamnd line parameters


Additional environment vars:
export GCPCT to configure the percentage of `%RAW USED` above which to trigger freeing of space.\
Example: `export GCPCT=25`


### Examples: ####
