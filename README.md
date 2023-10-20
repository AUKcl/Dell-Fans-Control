# Dell-Fans-Control
在Linux一键部署ipmitool工具，并自动控制戴尔服务器风扇转速，邮件通知运行结果

复制下列命令，执行一键安装脚本
```bash
sudo mkdir -p /root/ipmitool/ && wget https://github.com/AUKcl/Dell-Fans-Control/raw/main/Script/install.sh -P /root/ipmitool/ && chmod +x /root/ipmitool/install.sh && bash /root/ipmitool/install.sh
```

一键卸载脚本
```bash
sudo wget https://github.com/AUKcl/Dell-Fans-Control/raw/main/Script/uninstall.sh -P /root/ipmitool/ && chmod +x /root/ipmitool/uninstall.sh && bash /root/ipmitool/uninstall.sh
```

测试邮件设置
```bash
echo "test" | mail -s "hello" kaixuan135@outlook.com
```

查看邮件日志
```bash
cat /var/log/mail.log 
```