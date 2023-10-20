#!/bin/bash

# 设置IPMI连接参数
IP=<目标服务器IP地址>
USERNAME=<IPMI用户名>
PASSWORD=<IPMI密码>

# 设置通知邮箱地址
EMAIL=<通知邮箱地址>
# 创建临时目录用于存储运行状态
echo "创建临时目录用于存储运行状态"
TMP_DIR=$(mktemp -d)
# 创建运行状态文件
STATUS_FILE="$TMP_DIR/status.txt"
echo "戴尔风扇控制脚本运行中..." > $STATUS_FILE

# 发送通知邮件函数
send_notification() {
SUBJECT="戴尔风扇控制脚本运行状态"
BODY=$(cat $STATUS_FILE)
echo "$BODY" | mail -s "$SUBJECT" $EMAIL
}

# 开/关 风扇自动调节，当最后一个16进制数为0x00时为关闭，0x01时为开启
echo "关闭风扇自动调节"
ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x00
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x01

# 设置风扇转速0x14对应20%
# echo "创建临时目录用于存储运行状态"
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x14

# 设置风扇转速0x0f对应15%
echo "设置风扇转速0x0f对应15%"
ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x03 0xff 0x0f

# 设置风扇转速0x0a对应10%
# echo "创建临时目录用于存储运行状态"
# ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x04 0xff 0x0a

# 等待15min，待温度稳定后根据温度调整风扇转速
echo "等待15min，待温度稳定后根据温度调整风扇转速"
sleep 3

# 获取传感器温度
echo "获取传感器温度"
sensor_output=$(ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD sdr type temperature)

# 将得到类似如下输出
# Inlet Temp       | 04h | ok  |  7.1 | 19 degrees C
# Exhaust Temp     | 01h | ok  |  7.1 | 32 degrees C
# Temp             | 0Eh | ok  |  3.1 | 40 degrees C
# Temp             | 0Fh | ok  |  3.2 | 42 degrees C

# 解析传感器温度值
echo "解析传感器温度值"
temperature1=$(echo "$sensor_output" | grep "Temp" | awk 'NR==3 {print $NF}' | cut -d ' ' -f 1)
temperature2=$(echo "$sensor_output" | grep "Temp" | awk 'NR==4 {print $NF}' | cut -d ' ' -f 1)

# 计算温度平均值
echo "计算温度平均值"
average_temperature=$(( (temperature1 + temperature2) / 2 ))

# 根据传感器温度调整风扇转速
echo "根据传感器温度调整风扇转速"
if [ $average_temperature -ge 55 ]; then
    # 将风扇转速设置为20%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x14
elif [ $average_temperature -ge 47 ]; then
    # 将风扇转速设置为15%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0f
else
    # 将风扇转速设置为10%
    ipmitool -I lanplus -H $IP -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff 0x0a
fi

# 检查FanControl.sh运行状态
echo "检查FanControl.sh运行状态"
if [ $? -eq 0 ]; then
echo "FanControl.sh运行成功" >> $STATUS_FILE
else
echo "FanControl.sh运行失败" >> $STATUS_FILE
fi

# 发送通知邮件
echo "发送通知邮件"
send_notification

# 删除临时目录
echo "删除临时目录"
rm -rf $TMP_DIR
echo "戴尔风扇控制脚本运行完成"