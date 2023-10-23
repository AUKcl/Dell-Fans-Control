#!/bin/bash

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

# 获取当前时间的年月日、时分秒格式
CURRENT_TIME=$(date +"%Y%m%d_%H%M%S")

# 指定日志文件的目录
LOG_DIR="/root/ipmitool/log"

# 创建日志文件目录（如果不存在）
mkdir -p $LOG_DIR

# 设置日志文件路径，包括当前时间后缀
LOG_FILE="$LOG_DIR/logfile_$CURRENT_TIME.log"

# 开启日志
exec > >(tee -a $LOG_FILE) 2>&1

echo "戴尔服务器风扇定时控温脚本运行中..." 

# 发送通知邮件函数
send_notification() {
SUBJECT="戴尔服务器风扇定时控温脚本 - 运行失败，请检查服务器状态"
BODY=$(cat $LOG_FILE)
echo "$BODY" | mail -s "$SUBJECT" $EMAIL
}

# 获取传感器温度并设置超时
echo "获取传感器温度"
sensor_output=$(timeout $TIMEOUT ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD sdr type temperature)

# 判断是否超时
if [ $? -eq 124 ]; then
    echo "获取传感器温度超时"
    echo "获取传感器温度超时" >> $LOG_FILE
    send_notification
    exit 1
fi

echo "传感器温度结果: 
$sensor_output"

# 解析传感器温度值
echo "解析传感器温度值"
temperature1=$(echo "$sensor_output" | grep "Temp" | awk 'NR==3 {print $(NF-2)}' | cut -d ' ' -f 1)
temperature2=$(echo "$sensor_output" | grep "Temp" | awk 'NR==4 {print $(NF-2)}' | cut -d ' ' -f 1)
echo "CPU1: $temperature1 摄氏度"
echo "CPU2: $temperature2 摄氏度"

# 计算温度平均值
echo "计算温度平均值"
average_temperature=$(( (temperature1 + temperature2) / 2 ))
echo "CPU平均温度: $average_temperature"

# 根据传感器温度调整风扇转速
echo "根据传感器温度调整风扇转速"
if [ $average_temperature -ge 55 ]; then
    # 将风扇转速设置为20%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x14
    echo "风扇转速设置为20%"
elif [ $average_temperature -ge 47 ]; then
    # 将风扇转速设置为15%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0f
    echo "风扇转速设置为15%"
else
    # 将风扇转速设置为10%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0a
    echo "风扇转速设置为10%"
fi

# 设置退出时执行的清理操作
cleanup() {
    if [ $? -ne 0 ]; then
        echo "戴尔服务器风扇定时控温脚本运行失败" >> $LOG_FILE
        echo "戴尔服务器风扇定时控温脚本运行失败"
        send_notification
    fi
}

# 注册退出时的清理操作
trap cleanup EXIT

echo "戴尔服务器风扇定时控温脚本运行完成"