#!/bin/bash

# 获取当前时间的年月日、时分秒格式
CURRENT_TIME=$(date +"%Y%m%d_%H%M%S")

# 设置IPMI连接参数
IP=<目标服务器IP地址>
USERNAME=<IPMI用户名>
PASSWORD=<IPMI密码>

# 设置通知邮箱地址
EMAIL=<通知邮箱地址>

# 指定日志文件的目录
LOG_DIR="/root/ipmitool/log"

# 创建日志文件目录（如果不存在）
mkdir -p $LOG_DIR

# 设置日志文件路径，包括当前时间后缀
LOG_FILE="$LOG_DIR/logfile_$CURRENT_TIME.log"

# 开启日志
exec > >(tee -a $LOG_FILE) 2>&1

echo "戴尔风扇控制脚本运行中..." 

# 发送通知邮件函数
send_notification() {
SUBJECT="戴尔服务器风扇控制脚本 - Debug日志"
BODY=$(cat $LOG_FILE)
echo "$BODY" | mail -s "$SUBJECT" $EMAIL
}

# 开/关 风扇自动调节，当最后一个16进制数为0x00时为关闭，0x01时为开启
echo "关闭风扇自动调节"
ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x00
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x01

# 设置风扇转速0x14对应20%
# echo "设置风扇转速0x14对应20%"
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x14

# 设置风扇转速0x0f对应15%
# echo "设置风扇转速0x0f对应15%"
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x03 0xff 0x0f

# 设置风扇转速0x0a对应10%
echo "设置风扇转速0x0a对应10%"
ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x04 0xff 0x0a

# 等待15min，待温度稳定后根据温度调整风扇转速
echo "等待15min，待温度稳定后根据温度调整风扇转速"
sleep 900

# 获取传感器温度
echo "获取传感器温度"
sensor_output=$(ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD sdr type temperature)
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

# 检查FanControl.sh运行状态
echo "检查FanControl.sh运行状态"
if [ $? -eq 0 ]; then
    echo "FanControl.sh运行成功" >> $LOG_FILE
    echo "FanControl.sh运行成功"
else
    echo "FanControl.sh运行失败" >> $LOG_FILE
    echo "FanControl.sh运行失败"
fi

# 发送通知邮件
echo "发送通知邮件"
send_notification

echo "戴尔风扇控制脚本运行完成"
