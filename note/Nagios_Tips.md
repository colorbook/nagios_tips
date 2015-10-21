# Nagios_Tips
---
## 目的
收錄操作過程中瑣碎的設定與內容，並附上參考文獻。

## Tip1 修改 Limit Results
##### 敘述
修改 Nagios Web 單一頁面呈現的資料筆數。

##### 操作
在 cgi.cfg 設定檔修改內容
```bash
[root@NagiosServer ~]# vim /etc/nagios3/cgi.cfg
...
# DEFAULT PAGE LIMIT
# This option allows you to specify the default number of results
# displayed on the status.cgi.  This number can be adjusted from
# within the UI after the initial page load. Setting this to 0
# will show all results.

result_limit=0
```
##### 呈現結果
預設值改為 All，顯示所有資料。
![Limit_Results](../Picture_Nagios/Limit_Results.png)

##### 參考文獻
[Nagios and Nagios Related Information－NRPE](http://sites.box293.com/nagios/guides/nrpe/proxying-or-double-hopping/nrpe)

## Tip2 調整服務監控中止時間
##### 敘述
因監控服務等待過程耗費過久，已超過 Nagios 系統預設時間造成服務監控中止(出現 Service check timeout 訊息)，並且無法呈現監控資料，所以調整主設定檔參數 service_check_timeout。

##### 操作
利用 time 指令計算此監測服務需耗費多久時間
```bash
[root@NagiosServer]# time /etc/nagios3/conf.d/check_service -H 10.10.10.10
real    1m10.003s
user    0m10.004s
sys     0m10.000s 
```
在主設定檔 Nagios.cfg 修改內容
```bash
[root@NagiosServer]# vim /etc/nagios3/nagios.cfg
...
max_service_check_spread=10 #minute
service_check_timeout=120    #second
```
注意 max_service_check_spread 時間必須大於 service_check_timeout=120

##### 參考文獻
[Nagios Core－Main Configuration File Options](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/configmain.html)
