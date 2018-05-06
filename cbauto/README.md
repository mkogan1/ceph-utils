## cbauto ##
COSBench automation

### Description: ###
The cbauto utility automates submitting workloads to [COSBench](https://github.com/intel-cloud/cosbench)
With the intention of stress testing Ceph storage performance/memory usage.

### Pre-requisites: ###
Testest with [COSBench version v0.4.2 release candidate 4](https://github.com/intel-cloud/cosbench/releases/tag/v0.4.2.c4)

COSBench must be started before cbauto is run (`start-all.sh`)

cbauto looks for COSBbench installation at `../../cosbench` directory :\
`#  ls -l ../../cosbench`\
`lrwxrwxrwx. 1 root root 8 Feb 22 10:51 ../../cosbench -> 0.4.2.c4`


### Usage: ###
ssh keys
environment vars
comamnd line parameters

### Examples: ####
