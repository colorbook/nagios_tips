# Nagios SNMP Trap Interface Note
---

## 目的
透過此篇文章，您可以學到以下內容：
* SNMP Trap 運作概要
* Nagios SNMP Trap Interface(NSTI)安裝與設定

## 參考文獻
[Github－NSTI 3.0](https://github.com/NagiosEnterprises/nsti)
[NSTI 3.0 Document](https://nagiosenterprises.github.io/nsti/index.html)


## 版本資訊
* Nagios：Nagios Core 3.5.1
* Nagios Server OS：CentOS 6.7
* NSTI Package：NSTI 3.0.2

## 問題需求
在特定網域中佈建一套系統，系統設備包含防火牆、L2交換器、HP伺服器、光纖通道交換器(SAN Switch)、磁碟陣列(Storage)，必須思考透過何種機制去監控各設備運作情形。

## 解決方法概念
經研究發現各設備支援 SNMP Trap，並且 NSTI 套件可蒐集 SNMP Trap 資訊並以 WebUI 呈現，因此只要獲得設備 MIB 檔匯入監控主機就可監控各設備狀態。

## 解決方法細節
### Nagios Server 端(SNMP Srver)
1. 安裝 Nagios Server
	CentOS 6 在 yam 已經整合 Nagios Core 3.5 套件，因此直接使用套件安裝(要使用最新版 Nagios Core 請參照官網說明進行安裝)。
	```bash
    [root@NagiosServer ~]# yum update
    [root@NagiosServer ~]# yum install -y nagios*
    [root@NagiosServer ~]# htpasswd /etc/nagios/passwd nagiosadmin
	New password:
	Re-type new password:
	Updating password for user nagiosadmin
    [root@NagiosServer ~]# /etc/init.d/httpd start
    [root@NagiosServer ~]# /etc/init.d/nagios start
    ```
    
    安裝結束可以在瀏覽器測試 http://SERVER IP/nagios 安裝成功可以看到以下畫面，輸入方才設定的 Nagios 密碼就可登入 WebUI。
    ![Nagios Access](./Picture_Nagios/Nagios_Access.png)

2. 安裝 NSTI 套件
	從 [Github－NSTI 3.0](https://github.com/NagiosEnterprises/nsti) 下載套件並執行安裝腳本
    ```bash
    [root@NagiosServer ~]# git clone git clone https://github.com/NagiosEnterprises/nsti.git
    [root@NagiosServer ~]# sh /where/your/nsti_dir/install.sh
    ```
    安裝完成會在 nsti 資料夾中生成安裝記錄檔(install-timestamp.log)，詳細觀查記錄檔內容是否有錯誤訊息產生，如有錯誤訊息可參考官網 [Trouble Shooting](https://nagiosenterprises.github.io/nsti/installation.html#possible-nsti-install-gotcha-s)。

3. 設定 SNMPTT
	Snmptt 可將 MIB 檔轉換成可用的規則，簡言之是讓 SNMP Server 了解設備透過 SNMP Trap 送過來的資訊含意，因此就不用自行研究各設備 MIB。
    ```bash
    [root@NagiosServer ~]# for i in /usr/share/snmp/mibs/*
    do 
    snmpttconvertmib --in=$i --out=/etc/snmp/all_mib.conf 
    done
    ```
    上述將所有 MIB 檔透過 snmpttconvertmib 工具轉換成 snmptt 讀取的檔案，前提我們必須先獲得各設備 MIB 檔。接續設定 Snmptt ini 檔，指定讀取轉換後檔案(all_mib.conf)。
    ```bash
    [root@NagiosServer ~]# vim /etc/snmp/snmptt.ini
    ...
    unknown_trap_log_enable = 1
	description_mode = 1
	unknown_trap_exec = /etc/snmp/traphandle.sh
	snmptt_conf_files = <<END
	/etc/snmp/snmptt.conf
    /etc/snmp/all_mib.conf	#指定 snmptt 讀取的檔案
	END
    ```

4. 設定 SNMPTRAP
	設定 SNMP Trap 資訊輸出格式，相關參數請參考 [SNMPTRAPD](http://www.net-snmp.org/docs/man/snmptrapd.html#lbAE)。
    ```bash
    [root@NagiosServer ~]# vim /etc/init.d/snmptrapd
    ...
    OPTIONS="-On -Lsd -p /var/run/snmptrapd.pid"
    ```
    設定 SNMPTRAP 設定檔，相關參數請參考 [SNMPTRAPD.CONF](http://www.net-snmp.org/docs/man/snmptrapd.conf.html)
    ```bash
    [root@NagiosServer ~]# vim /etc/snmp/snmptrap.conf
    ...
    disableAuthorization yes	#為了讓資料傳輸更加安全，建議測試完後改為 no 並且設定 community
	traphandle default /usr/sbin/snmptthandler
    ```

5. 執行
	執行 SNMP 相關服務與 NSTI
    ```bash
    [root@NagiosServer ~]# /etc/init.d/snmpd start
    [root@NagiosServer ~]# /etc/init.d/snmptrapd start
    [root@NagiosServer ~]# /etc/init.d/snmptt start
    [root@NagiosServer ~]# python /where/your/nsti_dir/runserver.py
    * Running on http://0.0.0.0:8080/ (Press CTRL+C to quit)
    ```
    開啟瀏覽器輸入 http://YOUR IP/nsti，執行成功會看到以下畫面
    ![NSTI WebUI](./Picture_Nagios/NSTI_WebUI.png)

6. Trouble Shooting
	* NSTI 運作背後是使用 MySQL 資料庫，安裝過程會預先設定 root 密碼，可至安裝記錄檔查看。
	* [Github－NSTI 3.0 SNMPTT ](https://github.com/NagiosEnterprises/nsti/blob/master/docs/snmpttsetup.rst)有詳細 SNMP 相關設定
	* 詳細 NSTI 操作可參考 [NSTI 3.0 Document](https://nagiosenterprises.github.io/nsti/index.html)

### 監控設備端
1. 手動測試
	利用 snmptrap 工具測試能否將 SNMP Trap 傳送至 SNMP Server，snmptrap 用法請參考 [snmptrap command](http://linuxcommand.org/man_pages/snmptrap1.html)。
    ```bash
    [root@TestServer ~]# snmptrap -v 2c -c public 10.3.76.123 "" NET-SNMP-EXAMPLES-MIB::netSnmpExampleHeartbeatNotification netSnmpExampleHeartbeatRate i 123456
    ```
    在 SNMP Server /var/log/messages 查看是否有收到 SNMP Trap 資料
    ```bash
    [root@NagiosServer ~]# tail -f /var/log/messages
    ...
    Jan 20 08:05:42 NagiosServer snmptrapd[6374]: 2016-01-20 02:06:42 <UNKNOWN> [UDP: [10.3.76.123]:59307->[10.3.76.123]]:#012.1.3.6.1.2.1.1.3.0 = Timeticks: (2017719) 5:36:17.19#011.1.3.6.1.6.3.1.1.4.1.0 = OID: .1.3.6.1.4.1.8072.2.3.0.1#011.1.3.6.1.4.1.8072.2.3.2.1 = INTEGER: 123456
    ```
    此外，開啟 NSTI WebUI 確認是否有資料存取。