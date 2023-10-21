#    AutoBangumi-OneClickScrip
#    One-click deployment of the ipmitool on Linux, and automatic control of Dell server fan speed, with email notification of the execution result.
#    Copyright (C) <2023>  <AUKcl>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#    
#    AUKcl's email:kaixuan135@outloook.com

echo -e "${GREEN}欢迎使用 Dell-Fans-Control 一键部署脚本${PLAIN}"
echo -e "${GREEN}本程序将自动为您部署程序${PLAIN}"
echo -e "${GREEN}如果您遇到问题可以在这里寻找答案： ${PLAIN}"
echo -e "${YELLOW}https://github.com/AUKcl/Dell-Fans-Control${PLAIN}"

read -p "按下回车以继续..."

# 下载戴尔风扇控制脚本
download_fans_control_script() {
    echo "正在下载戴尔风扇控制脚本..."
    sudo mkdir -p /root/ipmitool/
    sudo wget -O /root/ipmitool/FansControl.sh https://github.com/AUKcl/Dell-Fans-Control/raw/main/Script/FansControl.sh
}

# 安装mailutils
install_mailutils() {
    echo "正在安装mailutils..."
    sudo apt-get update
    sudo apt-get install -y mailutils
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

    # 1. 设置 myhostname
    if ! grep -q "myhostname = " /etc/postfix/main.cf; then
        echo "myhostname = localhost" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|myhostname =.*|myhostname = localhost|" /etc/postfix/main.cf
    fi

    # 2. 设置 mydestination
    if ! grep -q "mydestination = " /etc/postfix/main.cf; then
        echo "mydestination = localhost" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|mydestination =.*|mydestination = localhost|" /etc/postfix/main.cf
    fi

    # 3. 设置 inet_interfaces
    if ! grep -q "inet_interfaces = " /etc/postfix/main.cf; then
        echo "inet_interfaces = loopback-only" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|inet_interfaces =.*|inet_interfaces = loopback-only|" /etc/postfix/main.cf
    fi

    # 4. 设置 relayhost
    if ! grep -q "relayhost = " /etc/postfix/main.cf; then
        echo "relayhost = [$SMTP_SERVER]:$SMTP_PORT" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|#relayhost =.*|relayhost = [$SMTP_SERVER]:$SMTP_PORT|" /etc/postfix/main.cf
    fi

    # 5. 启用 smtp_sasl_auth_enable
    if ! grep -q "smtp_sasl_auth_enable = " /etc/postfix/main.cf; then
        echo "smtp_sasl_auth_enable = yes" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|#smtp_sasl_auth_enable =.*|smtp_sasl_auth_enable = yes|" /etc/postfix/main.cf
    fi

    # 6. 设置 smtp_sasl_password_maps
    if ! grep -q "smtp_sasl_password_maps = " /etc/postfix/main.cf; then
        echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|#smtp_sasl_password_maps =.*|smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd|" /etc/postfix/main.cf
    fi

    # 7. 设置 smtp_generic_maps
    if ! grep -q "smtp_generic_maps = " /etc/postfix/main.cf; then
        echo "smtp_generic_maps = hash:/etc/postfix/generic" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|smtp_generic_maps =.*|smtp_generic_maps = hash:/etc/postfix/generic|" /etc/postfix/main.cf
    fi

    # 8. 设置 smtp_sasl_security_options
    if ! grep -q "smtp_sasl_security_options = " /etc/postfix/main.cf; then
        echo "smtp_sasl_security_options = noanonymous" | sudo tee -a /etc/postfix/main.cf > /dev/null
    else
        sudo sed -i "s|#smtp_sasl_security_options =.*|smtp_sasl_security_options = noanonymous|" /etc/postfix/main.cf
    fi

    # 9. 设置 sasl_passwd
    echo "[$SMTP_SERVER]:$SMTP_PORT    $SMTP_USERNAME:$SMTP_PASSWORD" | sudo tee /etc/postfix/sasl_passwd > /dev/null
    sudo postmap /etc/postfix/sasl_passwd
    sudo chmod 600 /etc/postfix/sasl_passwd

    # 10. 添加发件人映射
    hostname=$(hostname)
    current_user=$(whoami)
    sender_mapping="$current_user@$hostname $EMAIL"
    echo "$sender_mapping" | sudo tee -a /etc/postfix/generic > /dev/null
    sudo postmap /etc/postfix/generic

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

# 修改戴尔风扇控制脚本中的IP、用户名、密码和邮箱地址
replace_script_placeholders() {
    # 修改内容
    sed -i "s/<目标服务器IP地址>/$IP/" /root/ipmitool/FansControl.sh
    sed -i "s/<IPMI用户名>/$USERNAME/" /root/ipmitool/FansControl.sh
    sed -i "s/<IPMI密码>/$PASSWORD/" /root/ipmitool/FansControl.sh
    sed -i "s/<通知邮箱地址>/$EMAIL/" /root/ipmitool/FansControl.sh
}

# 执行一键安装脚本
install_script() {
    download_fans_control_script
    ask_ipmi_params
    ask_email_address
    replace_script_placeholders
    ask_smtp_details
    install_mailutils
    install_ipmitool
    install_postfix
    configure_postfix
    add_to_startup

    echo "安装完成！戴尔风扇控制脚本已添加到开机启动。"
}

# 执行一键安装脚本
install_script
