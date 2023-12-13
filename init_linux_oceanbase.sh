#!/bin/sh
#一键优化不会执行创建admin用户

. /etc/rc.d/init.d/functions
export LANG=en_US.UTF-8

#一级菜单
menu1()
{
        clear
        cat <<EOF
----------------------------------------
|****   欢迎使用cetnos7.9优化脚本    ****|
|****  一键优化不会执行创建admin用户  ****|
----------------------------------------
1. 一键优化
2. 自定义优化
3. 退出
EOF
        read -p "please enter your choice[1-3]:" num1
}

#二级菜单
menu2()
{
 clear
 cat <<EOF
----------------------------------------
|****Please Enter Your Choice:[0-10]****|
----------------------------------------
1. 内核参数设置
2. 修改文件描述符
3. 关闭SELINUX
4. 关闭firewalld
5. 配置时间同步chrony
6. 禁用ctrl+alt+del重启
7. 加快ssh登录速度
8. 创建admin账户
9 .返回上级菜单
10.退出
EOF
 read -p "please enter your choice[1-10]:" num2
 
}

#1. 优化操作系统内核
kernelset()
{
 echo "======================优化系统内核========================="
 chk_nf=`cat /etc/sysctl.conf | grep conntrack |wc -l`
 if [ $chk_nf -eq 0 ];then
  cat >>/etc/sysctl.conf<<EOF
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 10000
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.ip_local_port_range = 3500 65535
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_slow_start_after_idle=0
vm.swappiness = 0
vm.min_free_kbytes = 2097152
vm.max_map_count=655360
fs.aio-max-nr=1048576
fs.file-max = 655360
EOF
 sysctl -p
 else
  echo "优化项已存在。"
 fi
 action "内核调优完成" /bin/true
 echo "==========================================================="
 sleep 2
}

#2.修改文件描述符
limitset()
{
 echo "======================修改文件描述符======================="
 cat >>/etc/security/limits.conf<<EOF
* soft nofile 655360
* hard nofile 655360
* soft nproc 655360
* hard nproc 655360
* soft core unlimited
* hard core unlimited
* soft stack unlimited
* hard stack unlimited
EOF
 echo "session    required    pam_limits.so" >> /etc/pam.d/login
 sed -i 's/#UseLogin no/UseLogin yes/g' /etc/ssh/sshd_config
 sed -i 's/#UsePAM yes/UsePAM yes/g' /etc/ssh/sshd_config
 action "完成修改文件描述符" /bin/true
 echo "==========================================================="
 sleep 2
}

#3.关闭selinux
selinuxset() 
{
 selinux_status=`grep "SELINUX=disabled" /etc/sysconfig/selinux | wc -l`
 echo "========================禁用SELINUX========================"
 if [ $selinux_status -eq 0 ];then
  sed  -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/sysconfig/selinux
  setenforce 0
  echo '#grep SELINUX=disabled /etc/sysconfig/selinux'
  grep SELINUX=disabled /etc/sysconfig/selinux
  echo '#getenforce'
  getenforce
 else
  echo 'SELINUX已处于关闭状态'
  echo '#grep SELINUX=disabled /etc/sysconfig/selinux'
                grep SELINUX=disabled /etc/sysconfig/selinux
                echo '#getenforce'
                getenforce
 fi
  action "完成禁用SELINUX" /bin/true
 echo "==========================================================="
 sleep 2
}

#4.关闭firewalld
firewalldset()
{
 echo "=======================禁用firewalld========================"
 systemctl stop firewalld.service &> /dev/null
 echo '#firewall-cmd  --state'
 firewall-cmd  --state
 systemctl disable firewalld.service &> /dev/null
 echo '#systemctl list-unit-files | grep firewalld'
 systemctl list-unit-files | grep firewalld
 action "完成禁用firewalld，生产环境下建议启用！" /bin/true
 echo "==========================================================="
 sleep 5
}

#5. 设置时间同步
timesync()
{
 echo "=======================设置时间同步========================"
 yum -y install chrony &> /dev/null
 sed -i '3,6d' /etc/chrony.conf
 sed -i '3a server ntp1.aliyun.com\  iburst' /etc/chrony.conf
 sed -i '4a server ntp2.aliyun.com\  iburst' /etc/chrony.conf
 sed -i '5a server ntp3.aliyun.com\  iburst' /etc/chrony.conf
 if [ $? -eq 0 ];then
	timedatectl set-ntp false
	systemctl restart chronyd &>/dev/null
	timedatectl set-timezone Asia/Shanghai &>/dev/null
	hwclock --systohc --systz --localtime &>/dev/null
	chronyc -a makestep
	hwclock -s &>/dev/null
	hwclock -w &>/dev/null
  cat >>/etc/chrony.conf<<EOF
  driftfile /var/lib/chrony/drift
  makestep 1.0 3
  rtcsync
  local stratum 10
  logdir /var/log/chrony
EOF
 else
  echo "chrony安装失败"
  exit $?
 fi
 action "完成设置时间同步" /bin/true
 echo "==========================================================="
 sleep 2
}

#6. 禁用ctrl+alt+del重启
restartset()
{
 echo "===================禁用ctrl+alt+del重启===================="
 rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
 action "完成禁用ctrl+alt+del重启" /bin/true
 echo "==========================================================="
 sleep 2
}

#7.加快ssh登录速度
sshset()
{
 echo "======================加快ssh登录速度======================"
 sed -i 's#^GSSAPIAuthentication yes$#GSSAPIAuthentication no#g' /etc/ssh/sshd_config
 sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
 systemctl restart sshd.service
 echo "#grep GSSAPIAuthentication /etc/ssh/sshd_config"
 grep GSSAPIAuthentication /etc/ssh/sshd_config
 echo "#grep UseDNS /etc/ssh/sshd_config"
 grep UseDNS /etc/ssh/sshd_config
 action "完成加快ssh登录速度" /bin/true
 echo "==========================================================="
 sleep 2
}

8. 创建admin账户
crt_user()
{
  /usr/sbin/useradd admin
  echo 'admin:admin' | chpasswd
  usermod admin -G wheel
  action "完成admin用户创建并加入到wheel组" /bin/true
}


#控制函数
main()
{
 menu1
 case $num1 in
  1)
   kernelset
   limitset
   selinuxset
   firewalldset
   timesync
   restartset
   sshset
   ;;
  2)
   menu2
   case $num2 in
                  1)
                    kernelset
                    ;;
                  2)
                    limitset
                    ;;
                  3)
                    selinuxset
                    ;;
                  4)
                    firewalldset
                    ;;
                  5)
                    timesync
                    ;;
                  6)     
                    restartset
                    ;;
                  7)
                    sshset
                    ;;
                  8)
                    crt_user
                    ;;
                  9)
                    main
                    ;;
                  10)
                    exit
                    ;;
                  *)
      echo 'Please select a number from [1-10].'
      ;;
   esac
   ;;
  3)
   exit
   ;;
  *)
   echo 'Err:Please select a number from [1-3].'
   sleep 3
   main
   ;;
 esac
}
main $*
