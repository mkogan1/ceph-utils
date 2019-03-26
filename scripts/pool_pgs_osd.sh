#set -x

if [[ $(ceph pg dump 2>/dev/null | egrep -c "incomplete") -gt 0 ]]; then 
  echo "inclomplete pgs found, please fix and restart"
  exit 1
fi

POOL=${1:-default.rgw.buckets.data}
POOL_NUM=$(ceph osd pool stats ${POOL} 2>/dev/null | head -1 | awk "{print \$4}") 
date
echo "# POOL=${POOL} , POOL_NUM=${POOL_NUM}"
echo "# ceph -s"
ceph -s 2>/dev/null
ceph osd df 2>/dev/null
echo 
TMPF=$(mktemp /tmp/pgdump.XXXXXX)
ceph pg dump 2>/dev/null > $TMPF
echo -e "\n# PRIMARY PGs number per OSD sorted descending:"
for OSD in $(ceph osd ls 2>/dev/null); do printf "osd.$OSD\tPGs number: " ; printf "% 3d\n" "$(cat $TMPF | grep "^$POOL_NUM\." | awk '{print $16}' | grep -w $OSD | wc -l)" ; done | sort -n -r -k 4,4
rm $TMPF
echo 
SIZE=$(ceph osd dump 2>/dev/null | grep "pool $POOL_NUM" | awk '{ print $6 }')
NDEVS=`ceph osd ls 2>/dev/null | wc -l`
ceph pg dump 2>/dev/null | grep "^$POOL_NUM\." | awk "{ \
  seps[1]=\",\"; split(substr(\$17, 2, length(\$17)-2), res, seps[1]); \
  for (s = 0 ; s < $SIZE ; s++) { dist[s][res[s]]++; }
} END { \
  min=65535; max=0; sump=0; \
  for (i = 0 ; i < $NDEVS ; i++) { 
    printf(\" OSD%d PGs: %d %d %d total: %d\n\", i, dist[1][i], dist[2][i], dist[3][i], dist[1][i]+dist[2][i]+dist[3][i]); \
    printf(\"osd.%d\tPGs: %d %d %d total: %d\n\", i, dist[1][i], dist[2][i], dist[3][i], dist[1][i]+dist[2][i]+dist[3][i]); \
    for (s = 0 ; s < $SIZE ; s++) { 
    if (min > dist[1][i]) {min = dist[1][i]} \
    if (max < dist[1][i]) {max = dist[1][i] \
  } \
  sump+=dist[1][i]}; ratio=\"NaN\"; \
  if (min > 0){ratio=max/min}; \
  printf( \" Primary: Min=%d Max=%d Ratio=%s Average=%s Max/Ave=%s\n\", min,max,ratio,sump/$NDEVS,max/(sump/$NDEVS) )
}"

