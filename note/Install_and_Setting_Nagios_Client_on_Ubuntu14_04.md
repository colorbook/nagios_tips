# Install and Setting Nagios Client on Ubuntu 14.04
---
## 目的
透過此篇文章，您可以學到以下內容：
* 在 Ubuntu 14.04 上安裝 Nagios NREP (Nagios Remote Plugin Executor)
* 設定 Nagios NREP

## 參考文獻
[How To Install NRPE on Ubuntu 15.04, 14.04, 12.04 & LinuxMint](http://tecadmin.net/install-nrpe-on-ubuntu/)

## 問題需求
在 Ubuntu 14.04 上安裝 Nagios NREP，讓此設備做為 Nagios Client。

## 解決方法概念
Nagios 監控架構如下圖(截自官網)：
![Honeynet](./Picture_Nagios/Indirect_Check.png)
Nagios Client 安裝與設定步驟為，(1)安裝相關套件、(2)設定 NRPE 服務、(3)服務檢查與確認。

## 解決方法細節

1. 系統套件更新
	```bash
	[root@NagiosClient ~]# apt-cache update
	```

2. 安裝相關套件
	套件 openssl 提供 Nagios nrep 之間做 SSL 資料傳輸
    套件 nagios-nrpe-server 為安裝 NRPE
    套件 nagios-plugins 為安裝相關 plugins
    套件 nagios-nrpe-plugin 為後來發現無 check_nrpe 方法，所以安裝此套件
    套件 sysv-rc-conf 為設定 runlevel 時相對應服務開啟或關閉
	```bash
	[root@NagiosClient ~]# apt-get install openssl nagios-nrpe-server nagios-plugins nagios-nrpe-plugin sysv-rc-conf
	```

3. 設定 NRPE 服務
	參數 allowed_hosts 設定允許對應 IP 連線
	```bash
	[root@NagiosClient ~]# vim /etc/nagios/nrpe.cfg
    ...
    allowed_hosts=127.0.0.1,XXX.XXX.XXX.XXX
	```
    
    用 sysv-rc-conf 檢查是否預設系統開機時啟動 NRPE 服務，如無則用 sysv-rc-conf 設定。
    ```bash
    [root@NagiosClient ~]# sysv-rc-conf --list |grep nrpe
    nagios-nrpe- 0:off      1:off   2:on    3:on    4:on    5:on    6:off
    ```
    
    設定防火牆規則
    ```bash
    [root@NagiosClient ~]# iptables -t filter -A INPUT -p tcp --dport 5666
    ```

4. 服務檢查與確認
	檢查 NREP 服務是否有執行
    檢查 NREP 是否有對外服務
    檢查防火牆規則有無檔 NRPE 5666 埠口
	```bash
    [root@NagiosClient ~]# ps aux|grep nrpe
    nagios  854  0.0  0.0  23340  2456 ? Ss  12:10 0:00 /usr/sbin/nrpe -c /etc/nagios/nrpe.cfg -d
    
    [root@NagiosClient ~]# netstat -anp|grep 5666
    tcp    0  0 0.0.0.0:5666     0.0.0.0:*     LISTEN    -
	tcp6   0  0 :::5666          :::*          LISTEN    -
    
    [root@NagiosClient ~]# iptables -L -n| grep 5666
    tcp  --  0.0.0.0/0     0.0.0.0/0     tcp dpt:5666
    ```
    
    檢查 NRPE 運作是否正常
    ```bash
    [root@NagiosClient ~]# /usr/lib/nagios/plugins/check_nrpe -H XXX.XXX.XXX.XXX
    NRPE v2.15
    ```