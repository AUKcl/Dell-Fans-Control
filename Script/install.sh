#!/bin/bash

# 下载戴尔风扇控制脚本
download_fans_control_script() {
    echo "正在下载戴尔风扇控制脚本..."
    sudo mkdir -p /root/ipmitool/
    sudo wget -O /root/ipmitool/FansControl.sh https://github.com/AUKcl/Dell-Fans-Control/blob/main/Script/FansControl.sh
}

# 安装ipmitool
install_ipmitool() {
    echo "正在安装ipmitool..."
    sudo apt-get update
    sudo apt-get install -y ipmitool
}

# 询问用户SMTP服务器、端口号、用户名和密码
ask_smtp_details() {
    read -p "请输入SMTP服务器地址: " SMTP_SERVER
    read -p "请输入SMTP服务器端口号: " SMTP_PORT
    read -p "请输入SMTP用户名: " SMTP_USERNAME
    read -p "请输入SMTP密码: " SMTP_PASSWORD
}

# 安装Postfix
install_postfix() {
    echo "正在安装Postfix..."
    sudo debconf-set-selections <<< "postfix postfix/mailname string localhost"
    sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    sudo apt-get install -y postfix
}

# 配置Postfix
configure_postfix() {
    echo "正在配置Postfix..."
    sudo sed -i "s/myhostname =.*/myhostname = localhost/" /etc/postfix/main.cf
    sudo sed -i "s/mydestination =.*/mydestination = localhost/" /etc/postfix/main.cf
    sudo sed -i "s/inet_interfaces =.*/inet_interfaces = loopback-only/" /etc/postfix/main.cf
    sudo sed -i "s/#relayhost =.*/relayhost = [$SMTP_SERVER]:$SMTP_PORT/" /etc/postfix/main.cf
    sudo sed -i "s/#smtp_sasl_auth_enable =.*/smtp_sasl_auth_enable = yes/" /etc/postfix/main.cf
    sudo sed -i "s/#smtp_sasl_password_maps =.*/smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd/" /etc/postfix/main.cf
    sudo sed -i "s/#smtp_sasl_security_options =.*/smtp_sasl_security_options = noanonymous/" /etc/postfix/main.cf

    echo "[$SMTP_SERVER]:$SMTP_PORT    $SMTP_USERNAME:$SMTP_PASSWORD" | sudo tee /etc/postfix/sasl_passwd > /dev/null
    sudo postmap /etc/postfix/sasl_passwd
    sudo chmod 600 /etc/postfix/sasl_passwd
    sudo systemctl restart postfix
}

# 添加戴尔风扇控制脚本到开机启动
add_to_startup() {
    echo "正在将戴尔风扇控制脚本添加到开机启动..."
    sudo cp /root/ipmitool/FansControl.sh /etc/init.d/
    sudo chmod +x /etc/init.d/FansControl.sh
    sudo update-rc.d FansControl.sh defaults
}

# 询问用户IPMI连接参数
ask_ipmi_params() {
    read -p "请输入目标服务器IP地址: " IP
    read -p "请输入IPMI用户名: " USERNAME
    read -p "请输入IPMI密码: " PASSWORD
}

# 询问用户通知邮箱地址
ask_email_address() {
    read -p "请输入通知邮箱地址: " EMAIL
}

# 执行一键安装脚本
install_script() {
    download_fans_control_script
    ask_ipmi_params
    ask_email_address
    install_ipmitool
    ask_smtp_details
    install_postfix
    configure_postfix
    add_to_startup


    # 修改戴尔风扇控制脚本中的IP、用户名、密码和邮箱地址
    sed -i "s/<目标服务器IP地址>/$IP/" /root/ipmitool/FansControl.sh
    sed -i "s/<IPMI用户名>/$USERNAME/" /root/ipmitool/FansControl.sh
    sed -i "s/<IPMI密码>/$PASSWORD/" /root/ipmitool/FansControl.sh
    sed -i "s/<通知邮箱地址>/$EMAIL/" /root/ipmitool/FansControl.sh

    echo "安装完成！戴尔风扇控制脚本已添加到开机启动。"
}

# 执行一键安装脚本
install_script
