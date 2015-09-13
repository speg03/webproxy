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

# Transparent Proxy
yum install -y squid
cat <<EOF >/etc/squid/squid.conf
acl localnet src 192.168.133.0/24
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localnet
http_access allow localhost
http_access deny all
http_port 3128 transparent
coredump_dir /var/spool/squid
refresh_pattern . 0 20% 4320
visible_hostname webproxy.internal
EOF

systemctl enable squid
systemctl start squid

setsebool -P squid_use_tproxy on

firewall-cmd --permanent --zone=internal --add-port=3128/tcp
firewall-cmd --permanent \
             --direct --add-rule ipv4 nat PREROUTING 0 \
             -i enp0s8 -p tcp --dport 80 \
             -j REDIRECT --to-port 3128
firewall-cmd --permanent \
             --direct --add-rule ipv4 nat PREROUTING 0 \
             -i enp0s8 -p tcp --dport 443 \
             -j REDIRECT --to-port 3128
firewall-cmd --reload
