#!/bin/bash

#    Dell-Fans-Control
#    One-click deployment of the ipmitool tool on Linux, and automatic control of the fan speed on Dell servers, with email notifications of the execution results.
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

# 发送运行失败通知邮件函数
send_failure_notification() {
    SUBJECT="戴尔服务器风扇定时控温脚本 - 运行失败，请检查服务器状态"
    BODY=$(cat $LOG_FILE)
    echo "$BODY" | mail -s "$SUBJECT" $EMAIL
}

# 输出信息到日志文件和标准输出
log_and_output() {
    local message="$1"
    echo "$message"
}

# 获取当前时间的年月日、时分秒格式
CURRENT_TIME=$(date +"%Y%m%d_%H%M%S")

# 指定日志文件的目录
LOG_DIR="/root/ipmitool/log"

# 创建日志文件目录（如果不存在）
mkdir -p $LOG_DIR

# 设置日志文件路径，包括当前时间后缀
LOG_FILE="$LOG_DIR/FansControl_Stability_log_$CURRENT_TIME.log"

# 检查日志文件是否被成功设置
if [ -z "$LOG_FILE" ]; then
    log_and_output "错误：无法设置日志文件路径"
    exit 1
fi

# 开启日志
exec > >(tee -a $LOG_FILE) 2>&1

# 检查 exec 命令是否成功
if [ $? -ne 0 ]; then
    log_and_output "错误：无法开启日志"
    exit 1
fi

# 设置退出时执行的清理操作
cleanup() {
    if [ $? -ne 0 ]; then
        log_and_output "戴尔服务器风扇定时控温脚本运行失败"
        send_failure_notification
    fi
}

# 注册退出时的清理操作
trap cleanup EXIT

# 导入配置文件
source /root/ipmitool/config/config.cfg

# 检查IP是否可访问
if ! ping -c 1 -w 2 $IP > /dev/null; then
    log_and_output "无法访问服务器IP地址: $IP"
    exit 1
fi

log_and_output "戴尔服务器风扇定时控温脚本运行中..."

# 检查是否支持 IPMI
log_and_output "检查是否支持 IPMI"
ipmi_support=$(timeout $TIMEOUT ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD mc info 2>/dev/null)

# 判断IPMI是否超时
if [ $? -eq 124 ]; then
    log_and_output "获取 IPMI 信息超时"
    exit 1
fi

log_and_output "IPMI 信息:
$ipmi_support"

# 检查ipmitool的退出状态
if [ -z "$ipmi_support" ]; then
    log_and_output "Error: 无法建立 IPMI 会话，检查是否支持 IPMI 或配置文件是否正确。"
    exit 1
fi

# 获取传感器温度并设置超时
log_and_output "获取传感器温度"
sensor_output=$(timeout $TIMEOUT ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD sdr type temperature)

# 判断获取传感器温度是否超时
if [ $? -eq 124 ]; then
    log_and_output "获取传感器温度超时"
    exit 1
fi

log_and_output "传感器温度结果:
$sensor_output"

# 解析传感器温度值
log_and_output "解析传感器温度值"
temperature1=$(echo "$sensor_output" | grep "Temp" | awk 'NR==3 {print $(NF-2)}' | cut -d ' ' -f 1)
temperature2=$(echo "$sensor_output" | grep "Temp" | awk 'NR==4 {print $(NF-2)}' | cut -d ' ' -f 1)
log_and_output "CPU1: $temperature1 摄氏度"
log_and_output "CPU2: $temperature2 摄氏度"

# 计算温度平均值
log_and_output "计算温度平均值"
average_temperature=$(( (temperature1 + temperature2) / 2 ))
log_and_output "CPU平均温度: $average_temperature"

# 根据传感器温度调整风扇转速
log_and_output "根据传感器温度调整风扇转速"
if [ $average_temperature -ge 55 ]; then
    # 将风扇转速设置为20%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x14
    log_and_output "风扇转速设置为20%"
elif [ $average_temperature -ge 47 ]; then
    # 将风扇转速设置为15%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0f
    log_and_output "风扇转速设置为15%"
else
    # 将风扇转速设置为10%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0a
    log_and_output "风扇转速设置为10%"
fi

log_and_output "戴尔服务器风扇定时控温脚本运行完成"
