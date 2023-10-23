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

# 导入配置文件
source /root/ipmitool/config/config.cfg

# 恢复System Board Fans为自动调节
restore_fans_to_auto() {
    echo "正在恢复System Board Fans为自动调节..."
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
}

# 删除戴尔服务器风扇控制脚本和相关文件
remove_fans_control() {
    echo "从开机启动中删除 FansControl_Start.sh"
    sudo update-rc.d -f FansControl_Start.sh remove
    echo "删除 FansControl_Stability.sh 定时运行"
    crontab -l | grep -v "/root/ipmitool/FansControl_Stability.sh" | crontab -
    sudo rm -rf /root/ipmitool/
}

# 执行一键卸载脚本
uninstall_script() {
    restore_fans_to_auto
    uninstall_mailutils
    uninstall_ipmitool
    uninstall_postfix
    remove_fans_control

    echo "卸载完成！戴尔服务器风扇控制脚本和相关组件已被移除。"
}

# 执行一键卸载脚本
uninstall_script
