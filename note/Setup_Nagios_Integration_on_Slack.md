# Setup Nagios Integration on Slack
---

## 目的
透過此篇文章，您可以學到以下內容：
* 在 Nagios Server 設定，將監控訊息即時傳送至 Slack 平台。
* 在 Slack 平台中設定允許 Nagios Integration

## 參考文獻
[Slack－Nagios Integration Setup Instructions](https://slack.com/services/new/nagios)
[Nagios Core－Object Definitions](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/objectdefinitions.html)

## 版本資訊
* Nagios：Nagios Core 3.5.1
* Nagios Server OS：Debian 7
* Slack：1

## 問題需求
在團隊開發過程中，希望將 Nagios 與 Slack 做結合，能夠透過 Slack 即時獲取 Nagios 資訊，而不用在 Slack 與 Nagios 平台中切換。

## 解決方法概念
在團隊開發過程中，時常會使用 Slack 做為團隊溝通平台，目前 Slack 支援 Nagios Integration 功能，能夠將 Nagios 監控資訊傳送至 Slack 特定 Channel，藉此達到統一監控管理。Slack 官方即有 Nagios Integration 安裝設定說明，本篇便依照說明內容實做並記錄。

## 解決方法細節
### Nagios Server 端
1. 安裝套件
	```bash
    [root@NagiosServer ~]# apt-get update
    [root@NagiosServer ~]# apt-get install libwww-perl libcrypt-ssleay-perl
    ```
    
2. 下載程式碼
	```bash
    [root@NagiosServer ~]# wget https://raw.github.com/tinyspeck/services-examples/master/nagios.pl
    [root@NagiosServer ~]# cp nagios.pl /usr/local/bin/slack_nagios.pl
    [root@NagiosServer ~]# chmod 755 /usr/local/bin/slack_nagios.pl
    ```
    
3. 設定 Slack domain 與 token(請至 Slack Nagios Instegration 設定頁面獲取)
	```bash
    [root@NagiosServer ~]# vim /usr/local/bin/slack_nagios.pl
    ...
    my $opt_domain = "XXX.slack.com"; # Your team's domain
	my $opt_token = "abcs=defghijkl"; # The token from your Nagios services page
    ```
    
4. 設定 slack_nagios.cfg(相關 Nagios 參數設定請見參考文獻)
	slack_channel為必要設定，其指定的 Channel 必須事先手動設定，因本篇非使用 Nagios 4 版本，因此在 command 設定部分需添加 slack_channel 後的所有欄位設定，而新版 Nagios 4 則不用附加此設定。
	```bash
    [root@NagiosServer ~]# vim /etc/nagios3/conf.d/slack_nagios2.cfg
    ...
    define contact {
      contact_name                             slack
      alias                                    Slack
      service_notification_period              24x7
      host_notification_period                 24x7
      service_notification_options             w,u,c,r
      host_notification_options                d,r
      service_notification_commands            notify-service-by-slack
      host_notification_commands               notify-host-by-slack
	}
    
    define command {
      command_name notify-service-by-slack
      command_line /usr/local/bin/slack_nagios.pl -field slack_channel=#alerts -field HOSTALIAS="$HOSTNAME$" -field SERVICEDESC="$SERVICEDESC$" -field SERVICESTATE="$SERVICESTATE$" -field SERVICEOUTPUT="$SERVICEOUTPUT$" -field NOTIFICATIONTYPE="$NOTIFICATIONTYPE$"
	}

	define command {
      command_name notify-host-by-slack
      command_line /usr/local/bin/slack_nagios.pl -field slack_channel=#ops -field HOSTALIAS="$HOSTNAME$" -field HOSTSTATE="$HOSTSTATE$" -field HOSTOUTPUT="$HOSTOUTPUT$" -field NOTIFICATIONTYPE="$NOTIFICATIONTYPE$"
	}
    ```
    
5. 設定 contacts.cfg
	設定 Nagios 監控訊息傳送給 Slack 的設定
	```bash
    [root@NagiosServer ~]# vim /etc/nagios3/conf.d/contacts_nagios2.cfg
    ...
    define contactgroup {
  		contactgroup_name admins
  		alias             Nagios Administrators
  		members           root,slack
	}
    ```
6. 重啟 Nagios
	```bash
    [root@NagiosServer ~]# /etc/init.d/nagios3 restart
    ```

### Slack 端
* 設定 Slack Nagios Integration
	1. 在 Slack 官網中搜尋 Nagios Integration(截圖自 Slack 網站)
	![Slack_Nagios_Integration](./Picture_Nagios/Slack_Nagios_Integration.png)
    
    2. 新增 Nagios Integration(截圖自 Slack 網站)
    ![Slack_Nagios_Integration_Add](./Picture_Nagios/Slack_Nagios_Integration_Add.png)
    
    3. 此頁提供 Nagios Server 端安裝與設定說明、Slack domain、token 與其他設定資訊，設定好後點選儲存鍵。(截圖自 Slack 網站)
    ![Slack_Nagios_Integration_Save_Settings](./Picture_Nagios/Slack_Nagios_Integration_Save_Settings.png)
    
* 測試是否成功
	測試 Nagios command 是否能運作
    ```bash
    [root@NagiosServer ~]# /usr/local/bin/slack_nagios.pl -field slack_channel=#alerts
    ```
    
    在 Slack 出現的訊息如下(截圖自 Slack 網站)
    ![Slack_Nagios_Integration_Command_Check](./Picture_Nagios/Slack_Nagios_Integration_Command_Check.png)
    
	手動將 Nagios 監控設備關閉，當 Nagios 監控到設備異動時，便會發送訊息至 Slack 如下(截圖自 Slack 網站)。
    ![Slack_Nagios_Integration_Success](./Picture_Nagios/Slack_Nagios_Integration_Success.png)