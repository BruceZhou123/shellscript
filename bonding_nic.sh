#!/bin/bash
#创建一个名为bond0的链路接口
#Centos7.9可用，掩码24位

echo "请输入您绑定网卡的IP："
read IP
echo "请输入您绑定网卡的网关："
read GATE

nic_list=$(ls /sys/class/net/ | grep -v "`ls /sys/devices/virtual/net/`")
num=0
echo "All INTERFACE NETWORK: "$nic_list
for i in ${nic_list}
do
  if  [[ $i == docke* || $i == lo* || $i == vir* ]]
  then
    continue
  else
    num=`expr ${num} + 1`
    printf ${num}" "${i}"\t"
    echo `ethtool ${i}| grep dete`
  fi
done
echo "请输入您要绑定的第一块网卡名："
read ETH1
echo "请输入您要绑定的第二块网卡名："
read ETH2
modprobe bonding
echo "modprobe bonding" >>/etc/rc.local
chmod +x /etc/rc.local
#备份网卡1文件
cp /etc/sysconfig/network-scripts/ifcfg-$ETH1 ifcfg-$ETH1.bak
#修改网卡配置文件
function bond0()
{
cat<<EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
TYPE=bond
NAME=bond0
BONDING_MASTER=yes
BOOTPROTO=static
USERCTL=no
ONBOOT=yes
IPADDR=$IP
NETMASK=255.255.255.0
GATEWAY=$GATE
BONDING_OPTS="mode=4 miimon=100"
EOF
}
bond0

function eth1(){
cat<<EOF > /etc/sysconfig/network-scripts/ifcfg-$ETH1
TYPE=Ethernet
BOOTPROTO=none
DEVICE=$ETH1
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF
}
eth1

function eth2(){
cat<<EOF > /etc/sysconfig/network-scripts/ifcfg-$ETH2
TYPE=Ethernet
BOOTPROTO=none
DEVICE=$ETH2
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF
}
eth2

systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl restart network.service