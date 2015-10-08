# Use check_ping Method and Define Service Groups
---
## 目的
透過此篇文章，您可以學到以下內容：
* 利用 check_ping 方法測試監控設備狀況
* 利用 service groups 物件定義服務群組

## 參考文獻
[Object Definitions](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/objectdefinitions.html#servicegroup)

## 問題需求
監控各組設備存活狀態，並使用適當機制將狀態群組化，以利針對特定服務做觀察與監控。

## 解決方法概念
使用 Nagios 提供的 check_ping 方法，透過 icmp ping 的方式監控設備存活狀況，並且利用 service groups 物件方法將服務群組化。

## 解決方法細節

### Check_ping
1. 建立 check_ping 命令
	參數 -w 設定平均 ping 封包低於 300 毫秒且掉封包率低於 20%，否則發出 waring。
    參數 -c 設定平均 ping 封包低於 500 毫秒且掉封包率低於 80%，否則發出 critical。
	```bash
	[root@NagiosServer ~]# vim /etc/nagios3/commands.cfg
    ...
    define command{
    command_name    check_classc
    command_line    $USER1$/check_ping -H $ARG1$ -w 300,20% -c 500,80%
    }
	```
    
2. 設定監控服務
	```bash
	[root@NagiosServer ~]# vim /etc/nagios3/conf.d/check_ping_service.cfg
	...
	define service{
	        use                     generic-service
	        host_name               check_ping_host1
	        service_description     Ping host1
	        check_command           check_classc!xxx.xxx.xxx.xxx
	        }
	```

### Service Groups
1. 定義 service groups
	注意：members 設定格式為 *host1,service1,host2,service2,...,hostn,servicen*
	```bash
	define servicegroup{
			servicegroup_name   Ping_classc
			alias               Ping_classc
			members   			check_ping_host1,Ping host1,check_ping_host2,Ping host2
	```