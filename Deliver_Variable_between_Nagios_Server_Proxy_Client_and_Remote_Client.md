# Deliver Variable between Nagios Server, Proxy Client and Remote Client.
---
## 目的
透過此篇文章，您可以學到以下內容：
* Nagios Server、Proxy Client 與 Remote Client 之間命令設定
* 釐清設備間變數傳遞概念

## 參考文獻
[Nagios and Nagios Related Information－NRPE](http://sites.box293.com/nagios/guides/nrpe/proxying-or-double-hopping/nrpe)

## 問題需求
在設定 Nagios proxy 架構的命令與變數時，很容易將配置於不同設備的命令的變數混淆，因此有必要釐清，本文的 Nagios proxy 架構如下圖，架構說明請見 [Setting Nagios Client Proxy on CentOS7](./Setting_Nagios_Client_Proxy_on_CentOS7.md) ：

```
+--------+     +--------+    +--------+
| Nagios |     | Proxy  |    | Remote |
| Ser^er +-----+ Client +----+ Client |
+--------+     +--------+    +--------+
         Public         Pri^ate
```

## 解決方法概念
以下列舉兩個範例作為說明，範例一為檢查 Remote Client 的磁區容量；範例二利用 ping 方法檢查 Remote Client 上的虛擬機器連線狀況。

## 解決方法細節

### 範例一 檢查 Remote Client 磁區容量
#### 設定概念
透過 Proxy Client 代替 Nagios Server 查詢 Remote Client 磁碟容量，因此 Nagios Server 執行 check_nrpe 方法對 Proxy Client 連線，而 Porxy Client 執行 check_nrpe 方法命令 Remote Client 執行 check_disk 檢查容量狀態，最後將資料轉傳至 Nagios Server，概念圖如下：
```
+-------------+         +------------+         +-------------+
|Nagios Server|         |Proxy Client|         |Remote Client|
+-------------+         +------------+         +-------------+
|  check_nrpe +-------> | check_nrpe +-------> |  check_disk |
+-------------+         +------------+         +-------------+
```

#### Nagios Server 端設定
設定自訂命令
```bash
[root@NagiosServer ~]# vim /etc/nagios3/commands.cfg
...
define command{
    command_name    proxy_check_nrpe
    command_line    $USER1$/check_nrpe -H $ARG1$ -c proxy_check -a $ARG2$
    }
```

設定監控 Remote Client 設定檔，設定監控 Remote Client 磁碟容量服務。
```bash
[root@NagiosServer ~]# vim /etc/nagios3/conf.d/RemoteClient.cfg
...
define service{
        use                     generic-service
        host_name               RemoteClient
        service_description     Disk Space
        check_command           proxy_check_nrpe!<ProxyClientIP>!check_disk
        }
```

#### Proxy Client 端設定
```bash
[root@ProxyClient ~]# vim /etc/nagios/nrpe.cfg
...
command[proxy_check]=/usr/lib64/nagios/plugins/check_nrpe -t 60 -H <RemoteClientIP> -c $ARG1$
```

#### Remote Client 端設定
```bash
[root@RemoteClient ~]# vim /etc/nagios/nrpe.cfg
...
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /dev/sda -u GB
```

#### 釐清自訂命令與變數傳送
以下列出各設備所設定的命令，並指出設定的變數在設備間傳遞的情形。

```
+------+                                              
|Nagios|                                              
|Ser^er| check_nrpe +H $ARG1$ +c proxy_check +a $ARG2$
+------+                                          +   
                                                  |   
+------+                                          |   
|Proxy |                                          v   
|Client| check_nrpe +t 60 +H RemoteClientIP +c $ARG1$ 
+------+                                          +   
               +----------------------------------+   
+------+       |                                      
|Remote|       v                                      
|Client| check_disk +w 20% +c 10% +p /de^/sda +u GB   
+------+                                              

```

---
### 範例二 利用 ping 方法檢查 Remote Client 上的虛擬機器連線狀況
#### 設定概念
透過 Proxy Client 代替 Nagios Server 利用 ping 方法監控 Remote Client 內的虛擬機器的連線狀況，因此 Nagios Server 執行 check_nrpe 方法對 Proxy Client 連線，而 Porxy Client 執行 check_ping 方法，概念圖如下：
```
+-------------+         +------------+         +-------------+
|Nagios Ser^er|         |Proxy Client|         |Remote Client|
+-------------+         +------------+         +-------------+
|  check_nrpe +-------> | check_ping +-------> |             |
+-------------+         +------------+         +-------------+
```

#### Nagios Server 端設定
設定自訂命令
```bash
[root@NagiosServer ~]# vim /etc/nagios3/commands.cfg
...
define command{
    command_name    proxy_check_PingVM
    command_line    $USER1$/check_nrpe -H $ARG1$ -c check_ping -a $ARG2$
    }

```

設定監控 Remote Client 設定檔，設定 ping Remote Client 虛擬機器。
```bash
[root@NagiosServer ~]# vim /etc/nagios3/conf.d/RemoteClient.cfg
...
define service{
        use                     generic-service
        host_name               RemoteClient
        service_description     Ping VM
        check_command           proxy_check_PingVM!<ProxyClientIP>!<VMIP>
        }
```

#### Proxy Client 端設定
```bash
[root@ProxyClient ~]# vim /etc/nagios/nrpe.cfg
...
command[check_ping]=/usr/lib64/nagios/plugins/check_ping -H $ARG1$ -w 500,50% -c 1000,80%
```

#### 釐清變數傳送
Nagios Server $ARG1$ 指定 Proxy Client IP
```
+------+                                             
|Nagios|                                             
|Ser^er| check_nrpe -H $ARG1$ -c check_ping -a $ARG2$
+------+                              +          +   
              +-----------------------+          |   
+------+      |           +----------------------+   
|Proxy |      v           v                          
|Client| check_ping -H $ARG1$ -w 500,50% -c 1000,80% 
+------+                                             

```