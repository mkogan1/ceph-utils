#!/usr/bin/bash
#run: sudo nice bash ./system_low_level_data_collection.sh |& less -SR

set +x ; echo "========================================" ; set -x
if [[ $(cat /etc/redhat-release | grep -c Fedora) -eq 0 ]] && [[ $(yum repolist enabled | grep -c epel) -eq 0 ]]; then
  echo "please enable the EPEL repo and re-run"
  exit 1
fi
yum install -y lm_sensors perf msr-tools bc kernel-tools nvme-cli sg3_utils ethtool pciutils usbutils
yum install -y libhugetlbfs-utils

set +x ; echo "========================================" ; set -x
cat /proc/cmdline
uname -a
cat /etc/redhat-release
auditctl -l
getenforce
grep -H "" /sys/devices/system/cpu/vulnerabilities/*
set +x ; echo "========================================" ; set -x
lsmod | egrep "intel_powerclamp|processor_thermal_device|speedstep|cpufreq|power_meter"

systemctl status upower
systemctl status cpupower
systemctl status powertop
systemctl status tlp
systemctl status thermald
systemctl status tuned
tuned-adm profile

set +x ; echo "========================================" ; set -x
journalctl --disk-usage
systemctl status ntpd
systemctl status chronyd
#chronyc sources
chronyc tracking
timedatectl

cat /etc/resolv.conf
systemctl status dnsmasq
pgrep -a dnsmasq
pkill -USR1 dnsmasq ; journalctl --since="1 min ago" | grep dnsmasq

systemctl status fstrim.timer
lsblk -D
lsblk -t
echo "^^^ PHY-SEC"
cat /proc/scsi/scsi
lsblk -S
lsblk -Sn | awk '{ print $1 }' | xargs -t -i -n1 sginfo -a /dev/{}
lsblk -Sn | awk '{ print $1 }' | xargs -t -i -n1 sdparm -a /dev/{}
nvme list
nvme list | grep dev | awk '{ print $1 }' | xargs -t -i -n1  nvme smart-log {}
nvme list | grep dev | awk '{ print $1 }' | xargs -t -i -n1  nvme id-ctrl -H {}
mount | grep --color=always atime

cat /proc/cgroups | column -t
systemd-cgtop -n 1 -b -m

free -h
cat /proc/meminfo
hugeadm --explain
grep -H "" /sys/kernel/mm/transparent_hugepage/* 2> /dev/null
cat /sys/kernel/mm/ksm/run

set +x ; echo "========================================" ; set -x
perf stat -a --per-socket -e power/energy-pkg/ sleep 1 |& grep power
grep -H "" /sys/class/powercap/intel-rapl/intel-rapl:0/* 2>/dev/null
rdmsr -a 0x1AD
rdmsr -a 0x1AE
rdmsr -a 0x1AF
sensors
set +x
echo "|       |       |G C P  |      T| --> powercap by Gpu/Current/Power/Thermal" ; nice echo "ibase=16;obase=2;$(rdmsr 0x19c | tr '[:lower:]' '[:upper:]')" | bc
set -x
lscpu
cpupower monitor
cpupower frequency-info
echo -n '/sys/devices/system/cpu/cpufreq/schedutil/rate_limit_us = ' ; cat /sys/devices/system/cpu/cpufreq/schedutil/rate_limit_us 2>/dev/null
x86_energy_perf_policy -r
echo -n '/dev/cpu_dma_latency = ' ; hexdump -e '"%i\n"' /dev/cpu_dma_latency
grep -H "" /sys/devices/system/cpu/cpu0/cpuidle/state*/latency 2>/dev/null
cpupower idle-info
grep -H "" /sys/devices/system/cpu/cpuidle/* 2>/dev/null
zgrep CONFIG_CPU_IDLE_GOV /boot/config-$(uname -r)
set +x ; echo "========================================" ; set -x
grep -H "" /sys/devices/system/clocksource/*/*_clocksource 2>/dev/null
grep -H "" /sys/devices/system/cpu/cpu*/acpi_cppc/highest_perf 2>/dev/null
grep -H "" /sys/devices/system/cpu/cpu0/acpi_cppc/* 2>/dev/null
grep -H "" /proc/pressure/* 2>/dev/null
set +x ; echo "========================================" ; set -x
grep -H "" /sys/module/*/parameters/use_blk_mq 2>/dev/null
grep -H "" /sys/block/*/dm/use_blk_mq 2>/dev/null
grep -H "" /sys/block/*/device/subsystem/devices/*/scsi_host/*/use_blk_mq 2>/dev/null
grep -H "" /sys/block/*/queue/scheduler 2>/dev/null
grep -H "" /sys/block/*/queue/iosched/low_latency 2>/dev/null
grep -H "" /sys/block/*/queue/write_cache 2>/dev/null
grep -H "" /sys/block/*/queue/nr_requests 2>/dev/null
grep -H "" /sys/block/*/queue/read_ahead_kb 2>/dev/null
grep -H "" /sys/block/*/device/queue_depth 2>/dev/null
grep -H "" /sys/module/nvme_core/parameters/* 2>/dev/null
set +x ; echo "========================================" ; set -x
systemctl status firewalld
iptables -L

systemctl status irqbalance.service
cat /proc/interrupts
netstat -s
netstat -s | grep "timestamp"
netstat -s | egrep -i "reject|drop|reset|abort|err|unr|fail|retr"
ip -4 a
ip -s l
sudo sysctl -a | grep cast 2>/dev/null
sudo sysctl -a | grep arp 2>/dev/null
arp -n | wc -l
ip r
command ls -l /sys/class/net | grep pci | awk '{ print $9 }' | xargs -t -i -n1 ethtool {}
command ls -l /sys/class/net | grep pci | awk '{ print $9 }' | xargs -t -i -n1 ethtool -i {}
command ls -l /sys/class/net | grep pci | awk '{ print $9 }' | xargs -t -i -n1 ethtool -g {}
command ls -l /sys/class/net | grep pci | awk '{ print $9 }' | xargs -t -i -n1 ethtool -k {}

set +x ; echo "========================================" ; set -x
df -h | grep tmpfs
cat /proc/meminfo | grep "^Mapped"
ipcs
ipcs -m --human
ipcs -m -p
set +x ; echo "========================================" ; set -x
ulimit -aS
ulimit -aH
cat /etc/systemd/system.conf | grep -v "^#"
cat /etc/systemd/user.conf | grep -v "^#"

sysctl kernel.randomize_va_space
sysctl vm.dirty_background_ratio
sysctl vm.dirty_ratio
sysctl vm.dirty_background_bytes
sysctl vm.dirty_bytes
sysctl vm.swappiness
sysctl vm.overcommit_memory
sysctl vm.vfs_cache_pressure
sysctl vm.min_free_kbytes=262144
sysctl vm.min_free_kbytes=135168
sysctl kernel.sched_latency_ns
sysctl kernel.sched_min_granularity_ns
sysctl kernel.sched_wakeup_granularity_ns
sysctl kernel.sched_cfs_bandwidth_slice_us
sysctl kernel.sched_migration_cost_ns
sysctl kernel.sched_autogroup_enabled
sysctl vm.watermark_scale_factor
sysctl vm.zone_reclaim_mode
sysctl fs.inotify.max_user_watches
sysctl net.ipv6.conf.all.disable_ipv6
sysctl net.ipv6.conf.default.disable_ipv6
sysctl net.netfilter.nf_conntrack_tcp_be_liberal
sysctl net.ipv4.tcp_low_latency
sysctl net.ipv4.tcp_fastopen
sysctl net.ipv4.tcp_tw_reuse
sysctl net.core.busy_read
sysctl net.core.busy_poll
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_ecn
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_ecn
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_ecn
sysctl vm.dirty_writeback_centisecs=5 &> /dev/null
sysctl vm.dirty_expire_centisecs=30 &> /dev/null
sysctl kernel.nmi_watchdog=0 &> /dev/null
sysctl fs.file-max
sysctl -a 2>/dev/null
set +x ; echo "========================================" ; set -x
dmidecode
lspci -nnn
lspci -t -v
lspci -vvv
lspci -vvv | grep -i aspm
set +x ; echo "========================================" ; set -x
lsmod
grep -H "" /etc/modprobe.d/*
grep -H "" /proc/acpi/wakeup
cat /sys/module/usbcore/parameters/autosuspend
lsusb
lsusb -t
set +x ; echo "========================================" ; set -x
dmesg
set +x ; echo "========================================" ; set -x
