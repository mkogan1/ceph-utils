radosgw-admin user create --display-name="Test Id" --uid=testid --access-key b2345678901234567890 --secret b234567890123456789012345678901234567890 | jq
./ceph-utils/scripts/swift_init.sh
radosgw-admin zone placement modify --rgw-zone=default --placement-id=default-placement --compression=lz4 | jq
pgrep radosgw ; systemctl restart "ceph-radosgw@rgw*" ; sleep 2 ; pgrep radosgw

