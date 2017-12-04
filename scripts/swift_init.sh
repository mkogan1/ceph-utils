./bin/radosgw-admin user create --uid="cosbench" --display-name="cosbench"
./bin/radosgw-admin user modify --uid=cosbench --max-buckets=0
./bin/radosgw-admin subuser create --uid=cosbench --subuser=cosbench:operator --secret=redhat --access=full --key-type=swift
