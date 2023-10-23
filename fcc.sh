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

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
PLAIN="\e[0m"

# 定义配置文件路径
CONFIG_FILE="/root/ipmitool/config/config.cfg"

# 主菜单
main_menu() {
    while true; do
            # 输出欢迎消息
        echo -e "${GREEN}欢迎使用 Dell-Fans-Control 一键部署脚本${PLAIN}"
        echo -e "${GREEN}本程序将为您快速修改配置文件${PLAIN}"
        echo -e "${GREEN}如果您遇到问题可以在这里寻找答案： ${PLAIN}"
        echo -e "${YELLOW}https://github.com/AUKcl/Dell-Fans-Control${PLAIN}"
        echo "————————————————————————————————————————————————————————————————————————————"
        echo "请选择要修改的配置参数："
        echo "1. 目标服务器IP地址"
        echo "2. IPMI用户名"
        echo "3. IPMI密码"
        echo "4. 通知邮箱地址"
        echo "5. SMTP服务器地址"
        echo "6. SMTP服务器端口号"
        echo "7. SMTP用户名"
        echo "8. SMTP密码"
        echo "9. 脚本运行超时参数"
        echo "10. 退出脚本"

        read -p "请输入选项 (1-10): " choice

        case $choice in
            1)
                update_ip
                ;;
            2)
                update_username
                ;;
            3)
                update_password
                ;;
            4)
                update_email
                ;;
            5)
                update_smtp_server
                ;;
            6)
                update_smtp_port
                ;;
            7)
                update_smtp_username
                ;;
            8)
                update_smtp_password
                ;;
            9)
                update_timeout
                ;;
            10)
                exit 0
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

# 二级菜单选项
update_ip() {
    while true; do
        echo "1. 请输入新的目标服务器IP地址"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的目标服务器IP地址: " new_ip
                sed -i "s/IP=.*/IP=$new_ip/" $CONFIG_FILE
                echo "已更新目标服务器IP地址为: $new_ip"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_username() {
    while true; do
        echo "1. 请输入新的IPMI用户名"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的IPMI用户名: " new_username
                sed -i "s/USERNAME=.*/USERNAME=$new_username/" $CONFIG_FILE
                echo "已更新IPMI用户名为: $new_username"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_password() {
    while true; do
        echo "1. 请输入新的IPMI密码"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的IPMI密码: " new_password
                sed -i "s/PASSWORD=.*/PASSWORD=$new_password/" $CONFIG_FILE
                echo "已更新IPMI密码"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_email() {
    while true; do
        echo "1. 请输入新的通知邮箱地址"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的通知邮箱地址: " new_email
                sed -i "s/EMAIL=.*/EMAIL=$new_email/" $CONFIG_FILE
                echo "已更新通知邮箱地址为: $new_email"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_smtp_server() {
    while true; do
        echo "1. 请输入新的SMTP服务器地址"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的SMTP服务器地址: " new_smtp_server
                sed -i "s/SMTP_SERVER=.*/SMTP_SERVER=$new_smtp_server/" $CONFIG_FILE
                echo "已更新SMTP服务器地址为: $new_smtp_server"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_smtp_port() {
    while true; do
        echo "1. 请输入新的SMTP服务器端口号"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的SMTP服务器端口号: " new_smtp_port
                sed -i "s/SMTP_PORT=.*/SMTP_PORT=$new_smtp_port/" $CONFIG_FILE
                echo "已更新SMTP服务器端口号为: $new_smtp_port"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_smtp_username() {
    while true; do
        echo "1. 请输入新的SMTP用户名"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的SMTP用户名: " new_smtp_username
                sed -i "s/SMTP_USERNAME=.*/SMTP_USERNAME=$new_smtp_username/" $CONFIG_FILE
                echo "已更新SMTP用户名为: $new_smtp_username"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_smtp_password() {
    while true; do
        echo "1. 请输入新的SMTP密码"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的SMTP密码: " new_smtp_password
                sed -i "s/SMTP_PASSWORD=.*/SMTP_PASSWORD=$new_smtp_password/" $CONFIG_FILE
                echo "已更新SMTP密码"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

update_timeout() {
    while true; do
        echo "1. 请输入新的脚本运行超时参数"
        echo "2. 返回上一级"
        read -p "请输入选项 (1-2): " choice

        case $choice in
            1)
                read -p "请输入新的脚本运行超时参数: " new_timeout
                sed -i "s/TIMEOUT=.*/TIMEOUT=$new_timeout/" $CONFIG_FILE
                echo "已更新脚本运行超时参数为: $new_timeout"
                ;;
            2)
                return
                ;;
            *)
                echo "无效的选项"
                ;;
        esac
    done
}

# 启动主菜单
main_menu
