#!/bin/sh
#root权限执行

. /etc/rc.d/init.d/functions
export LANG=zh_CN.UTF-8

#一级菜单
menu1()
{
        clear
        cat <<EOF
----------------------------------------
|****   欢迎使用cetnos7.9优化脚本    ****|
|****      oracle 11g pre set       ****|
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
|****Please Enter Your Choice:[1-16]****|
----------------------------------------
1. 修改字符集
2. 关闭selinux
3. 关闭firewalld
4. 精简开机启动
5. 内核参数设置
6. Limits设置
7. 依赖包安装
8. hosts设置
9. 加快ssh登录速度
10. 禁用ctrl+alt+del重启
11. 设置时间同步
12. 关闭透明大页
13. 创建目录、组及用户
14. 设置grid、oracle用户环境变量
15. 返回上级菜单
16. 退出
EOF
 read -p "please enter your choice[1-16]:" num2
 
}

#1.修改字符集
localeset()
{
 echo "========================修改字符集========================="
 cat > /etc/locale.conf <<EOF
#LANG="zh_CN.UTF-8"
LANG="en_US.UTF-8"
SYSFONT="latarcyrheb-sun16"
EOF
 source /etc/locale.conf
 echo "#cat /etc/locale.conf"
 cat /etc/locale.conf
 action "完成修改字符集" /bin/true
 echo "==========================================================="
 sleep 2
}

#2.关闭selinux
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

#3.关闭firewalld
firewalldset()
{
 echo "=======================禁用firewalld========================"
 systemctl stop firewalld.service &> /dev/null
 echo '#firewall-cmd  --state'
 firewall-cmd  --state
 systemctl disable firewalld.service &> /dev/null
 echo '#systemctl list-unit-files | grep firewalld'
 systemctl list-unit-files | grep firewalld
 action "完成禁用firewalld,生产环境下建议启用！" /bin/true
 echo "==========================================================="
 sleep 5
}

#4.精简开机启动
chkset()
{
 echo "=======================精简开机启动========================"
 systemctl disable auditd.service
 systemctl disable postfix.service
 systemctl disable dbus-org.freedesktop.NetworkManager.service
 echo '#systemctl list-unit-files | grep -E "auditd|postfix|dbus-org\.freedesktop\.NetworkManager"'
 systemctl list-unit-files | grep -E "auditd|postfix|dbus-org\.freedesktop\.NetworkManager"
 action "完成精简开机启动" /bin/true
 echo "==========================================================="
 sleep 2
}

#5. 优化系统内核
kernelset()
{

 echo "======================优化系统内核========================="
 chk_nf=`cat /etc/sysctl.conf | grep conntrack |wc -l`
 if [ $chk_nf -eq 0 ];then
  cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 9000 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 0
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
fs.file-max = 6815744
fs.aio-max-nr = 1048576
net.core.rmem_default = 262144
net.core.rmem_max= 4194304
net.core.wmem_default= 262144
net.core.wmem_max= 1048576
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
EOF
MEMTOTAL=$(free -b | sed -n '2p' | awk '{print $2}')
SHMMAX=$(expr $MEMTOTAL / 2)
SHMALL=$[($SHMMAX/4096)*(4096/16)]
eval echo "kernel.shmmax=$SHMMAX" >>/etc/sysctl.conf
eval echo "kernel.shmall=$SHMALL" >>/etc/sysctl.conf
 sysctl -p
 else
  echo "优化项已存在。"
 fi
 action "内核调优完成" /bin/true
 echo "==========================================================="
 sleep 2
}

#6.修改文件描述符-limits.conf
limitset()
{
 echo "======================修改文件描述符======================="
 echo '* - nofile 65535'>/etc/security/limits.conf
 cat >> /etc/security/limits.conf <<EOF
  oracle soft nproc 2047
  oracle hard nproc 16384
  oracle soft nofile 4096
  oracle hard nofile 65536
  oracle soft stack 10240
  oracle hard stack 32768
  grid soft nproc 2047
  grid hard nproc 16384
  grid soft nofile 4096
  grid hard nofile 65536
  grid soft stack 10240
  grid hard stack 32768
  oracle hard memlock unlimited
  oracle soft memlock unlimited
EOF
 ulimit -SHn 65535
 echo "#cat /etc/security/limits.conf"
 cat /etc/security/limits.conf
 echo "#ulimit -Sn ; ulimit -Hn"
 ulimit -Sn ; ulimit -Hn
 echo "session    required    pam_limits.so" >> /etc/pam.d/login
 action "完成修改文件描述符" /bin/true
 echo "==========================================================="
 sleep 2
}


#7.安装常用工具及修改yum源
inst_rpm()
{
  ping -c 1 mirrors.aliyun.com &> /dev/null
  if [ $? -eq 0 ];then
   yum -y install binutils compat-libstdc++-33 gcc gcc-c++ glibc glibc-common glibc-devel ksh libaio libaio-devel libgcc libstdc++ \
   libstdc++-devel make sysstat openssh-clients compat-libcap1 xorg-x11-utils xorg-x11-xauth elfutils unixODBC unixODBC-devel libXp \
   elfutils-libelf elfutils-libelf-devel smartmontools unzip net-tools
   yum clean all &> /dev/null
   yum makecache &> /dev/null
   action "已安装11g oracle所需的RPM包" /bin/true
  else
   echo "无法连接网络"
       exit $?
    fi
  
}

#8.设置hosts
set_hosts()
{
  echo "===请根据需要设置hosts==="
  cat >> /etc/hosts <<EOF
# Public
192.168.200.70 rac1
192.168.200.71 rac2

# Virtual
192.168.200.72 rac1-vip
192.168.200.73 rac2-vip

# Private
192.168.30.1 rac1-priv
192.168.30.2 rac2-priv

# Scan-ip
192.168.200.75 rac-scan
EOF
action "已设置完hosts" /bin/true
}

#9.加快ssh登录速度
sshset()
{
 echo "======================加快ssh登录速度======================"
 sed -i 's#^GSSAPIAuthentication yes$#GSSAPIAuthentication no#g' /etc/ssh/sshd_config
 sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
 echo "======若将ssh端口改为非默认端口,可更改/etc/services中ssh端口设置======"
 systemctl restart sshd.service
 echo "#grep GSSAPIAuthentication /etc/ssh/sshd_config"
 grep GSSAPIAuthentication /etc/ssh/sshd_config
 echo "#grep UseDNS /etc/ssh/sshd_config"
 grep UseDNS /etc/ssh/sshd_config
 action "完成加快ssh登录速度" /bin/true
 echo "==========================================================="
 sleep 2
}

#10. 禁用ctrl+alt+del重启
restartset()
{
 echo "===================禁用ctrl+alt+del重启===================="
 rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
 action "完成禁用ctrl+alt+del重启" /bin/true
 echo "==========================================================="
 sleep 2
}

#11. 设置时间同步
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
 else
  echo "chrony安装失败"
  exit $?
 fi
 action "完成设置时间同步" /bin/true
 echo "==========================================================="
 sleep 2
}

#11. history优化
historyset()
{
 echo "========================history优化========================"
 chk_his=`cat /etc/profile | grep HISTTIMEFORMAT |wc -l`
 if [ $chk_his -eq 0 ];then
  cat >> /etc/profile <<'EOF'
#设置history格式
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] [`whoami`] [`who am i|awk '{print $NF}'|sed -r 's#[()]##g'`]: "
#记录shell执行的每一条命令
export PROMPT_COMMAND='\
if [ -z "$OLD_PWD" ];then
    export OLD_PWD=$PWD;
fi;
if [ ! -z "$LAST_CMD" ] && [ "$(history 1)" != "$LAST_CMD" ]; then
    logger -t `whoami`_shell_dir "[$OLD_PWD]$(history 1)";
fi;
export LAST_CMD="$(history 1)";
export OLD_PWD=$PWD;'
EOF
  source /etc/profile
 else
  echo "优化项已存在。"
 fi
 action "完成history优化" /bin/true
 echo "==========================================================="
 sleep 2
}

#12.关闭透明大页
dis_hu()
{
  echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled;then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag;then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi" >>/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
action "透明大页关闭成功！" /bin/true

}

#13. 创建oracle用户组及对应目录
crt_user()
{
  /usr/sbin/groupadd -g 54321 oinstall
  /usr/sbin/groupadd -g 54322 dba
  /usr/sbin/groupadd -g 54323 oper
  /usr/sbin/groupadd -g 54324 backupdba
  /usr/sbin/groupadd -g 54325 dgdba
  /usr/sbin/groupadd -g 54326 kmdba
  /usr/sbin/groupadd -g 54327 asmdba
  /usr/sbin/groupadd -g 54328 asmoper
  /usr/sbin/groupadd -g 54329 asmadmin
  /usr/sbin/groupadd -g 54330 racdba
  /usr/sbin/useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,asmdba,racdba oracle
  /usr/sbin/useradd -u 54322 -g oinstall -G dba,asmadmin,asmdba,asmoper,racdba grid
  
  echo "oracle" | passwd --stdin oracle 
  echo "grid" | passwd --stdin grid
  mkdir -p /u01/app/11.2.0/grid
  mkdir -p /u01/app/grid
  mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
  mkdir -p /u01/app/oraInventory
  chown -R grid:oinstall /u01
  chown -R oracle:oinstall /u01/app/oracle
  chmod 775 /u01/
  action "完成oracle用户、用户组及目录创建优化" /bin/true
}

#14. 设置用户环境变量(.bash_profile)
set_bsh()
{
  echo "====修改grid用户环境变量,请根据需要修改===="

 cat >> /home/grid/.bash_profile <<EOF
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/11.2.0/grid
export ORACLE_SID=+ASM1   #--节点2是 +ASM2
export NLS_LANG=american_america.ZHS16GBK
export NLS_DATE_FORMAT="yyyy-mm-dd hh24:mi:ss"
export PATH=$ORACLE_HOME/bin:$PATH:${ORACLE_HOME}/OPatch
export ORACLE_TERM=xterm
export THREADS_FLAG=native
export TEMP=/tmp
export TMPDIR=/tmp
umask 022
export TMOUT=0
export DISPLAY=192.168.200.1:0.0
EOF
chown grid:oinstall /home/grid/.bash_profile

echo "====修改oracle用户环境变量,请根据需要修改===="
cat >> /home/oracle/.bash_profile <<EOF
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=sprod1   #--节点2是 xkdb2
export LANG=en_US.UTF-8
export NLS_LANG=american_america.ZHS16GBK
export NLS_DATE_FORMAT="yyyy-mm-dd hh24:mi:ss"
export PATH=$ORACLE_HOME/bin:$PATH:${ORACLE_HOME}/OPatch
export TEMP=/tmp
export TMPDIR=/tmp
export GI_HOME=/oracle/app/11.2.0/grid
export PATH=${PATH}:$GI_HOME/bin
umask 022
export TMOUT=0
export DISPLAY=192.168.200.1:0.0
EOF
chown oracle:oinstall /home/oracle/.bash_profile
action "完成oracle用户、用户组及目录创建优化" /bin/true

}

#控制函数
main()
{
 menu1
 case $num1 in
  1)
   localeset
   selinuxset
   firewalldset
   kernelset
   limitset
   inst_rpm
   set_hosts
   sshset
   restartset
   timesync
   historyset
   dis_hu
   crt_user
   set_bsh
   ;;
  2)
   menu2
   case $num2 in
                  1)
                    localeset
                    ;;
                  2)
                    selinuxset
                    ;;
                  3)
                    firewalldset
                    ;;
                  4)
                    kernelset
                    ;;
                  5)
                    limitset
                    ;;
                  6)     
                    inst_rpm
                    ;;
                  7)
                    set_hosts
                    ;;
                  8)
                    sshset
                    ;;
                  9)
                    restartset
                    ;;
                  10)
                   timesync 
                    ;;
    11)
      historyset
      ;;
    12)
      dis_hu
      ;;
    13)
      crt_user
      ;;
    14)
      set_bsh
      ;;
    15)
      main
      ;;
    16)
      exit
      ;;
    *)
      echo 'Please select a number from [1-16].'
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
