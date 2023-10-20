# 恢复System Board Fans为自动调节
restore_fans_to_auto() {
    # 设置IPMI连接参数
    read -p "请输入目标服务器IP地址: " IP
    read -p "请输入IPMI用户名: " USERNAME
    read -s -p "请输入IPMI密码: " PASSWORD
    echo  # 换行以使输出更清晰
    echo "恢复 System Board Fans 为自动调节"
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x01
    echo "System Board Fans 已恢复为自动调节"
}

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
    sudo rm -rf /etc/postfix
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
    restore_fans_to_auto
    uninstall_mailutils
    uninstall_ipmitool
    uninstall_postfix
    remove_fans_control

    echo "卸载完成！戴尔风扇控制脚本和相关组件已被移除。"
}

# 执行一键卸载脚本
uninstall_script
