#!/bin/sh

# enable SELinux
setenforce enforcing
sed -i -e 's/^SELINUX=permissive$/SELINUX=enforcing/g' /etc/selinux/config

# enable firewalld
systemctl enable firewalld
systemctl start firewalld

# NAT
echo "1" >/proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >/etc/sysctl.d/00-sysctl.conf
firewall-cmd --set-default-zone internal

## It doesn't work. I don't know why.
##   firewall-cmd --permanent --zone=external --change-interface=enp0s3
##   firewall-cmd --reload
## use nmcli instead of firewall-cmd
nmcli connection modify enp0s3 connection.zone external
