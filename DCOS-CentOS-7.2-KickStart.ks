# (C) Copyright 2015-2016 Hewlett Packard Enterprise Development LP
lang en_US.UTF-8
keyboard us
timezone --utc America/Chicago
text 
install
skipx
network  --bootproto=dhcp 

authconfig --enableshadow --enablemd5
#rootpw --iscrypted "@encrypted_root_password:$1$7z4m7f1z$wliShMhVv2HuCAPmuiQzV1@"
rootpw "@root_password:password@"

zerombr
clearpart --all --initlabel 
autopart

bootloader --append="@kernel_arguments: @" --location=mbr

# Disable firewall and selinux for SPP components
firewall --disabled
# Port 1002 is needed for agent communication if the firewall is enabled
# firewall --enable --port=1002:tcp
selinux --disabled

%pre
# Set FCOEwait Custom Attribute to 120 seconds when deploying to FCOE SAN through 
# Broadcom CNA to allow FCOE driver to load correctly
sleep @FCOEwait:0@
%end

%packages
@Base
# Needed to ensure Mellanox driver installed when required
#kmod-mlnx-ofa_kernel

# Components listed below are needed for mount to media server for HPSUM installation
keyutils
libtalloc
cifs-utils

# Components listed below are needed to run HPSUM and SPP components
expect
libhbaapi
make
net-snmp
net-snmp-libs

%post --log=/root/icsp-post.log
echo 'Starting KickStart post configuration'
# Enable OnBoot on ethernet network interface ifcfg-enX (X=2 on gen8, X=50 on Gen9)
if_name=`ifconfig | grep eno | cut --delimiter=: -f 1`
echo "Changing ifcfg-$if_name configuration"
sed -i -e '/^ONBOOT=*/ s/no/yes/' /etc/sysconfig/network-scripts/ifcfg-$if_name
sed -i "$ a DHCP_HOSTNAME=`hostname -s`" /etc/sysconfig/network-scripts/ifcfg-$if_name
more /etc/sysconfig/network-scripts/ifcfg-$if_name

# Loading OverlayFS for Docker
echo Loading OverlayFS for Docker
tee /etc/modules-load.d/overlay.conf <<EOF
overlay
EOF

# Add link to python interpreter
echo 'Add link to python interpreter'
ln -sf /usr/bin/python /usr/local/bin/python2.7

# configure ntp
echo "Configure to use NTP"
echo "--------------------"
yum install -y ntp ntpdate ntp-doc
systemctl enable ntpd
systemctl start ntpd

echo 'Finished with KickStart post configuration'

%end