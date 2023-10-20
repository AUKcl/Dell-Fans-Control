# 卸载mailutils
uninstall_mailutils() {
    echo "正在卸载mailutils..."
    sudo apt-get remove -y mailutils
}

# 卸载ipmitool
uninstall_ipmitool() {
    echo "正在卸载ipmitool..."
    sudo apt-get remove -y ipmitool
}

# 卸载Postfix
uninstall_postfix() {
    echo "正在卸载Postfix..."
    sudo apt-get remove -y postfix
    sudo rm /etc/postfix/sasl_passwd
    sudo rm /etc/postfix/sasl_passwd.db
}

# 删除戴尔风扇控制脚本和相关文件
remove_fans_control() {
    echo "正在删除戴尔风扇控制脚本和相关文件..."
    sudo update-rc.d -f FansControl.sh remove
    sudo rm /etc/init.d/FansControl.sh
    sudo rm -rf /root/ipmitool/
}

# 执行一键卸载脚本
uninstall_script() {
    uninstall_mailutils
    uninstall_ipmitool
    uninstall_postfix
    remove_fans_control

    echo "卸载完成！戴尔风扇控制脚本和相关组件已被移除。"
}

# 执行一键卸载脚本
uninstall_script
