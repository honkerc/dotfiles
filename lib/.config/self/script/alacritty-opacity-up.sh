#!/bin/bash

CONFIG_FILE="$HOME/.config/alacritty/alacritty.toml"

# 获取当前 opacity 值
current_line=$(grep -n '^opacity' "$CONFIG_FILE")
if [ -z "$current_line" ]; then
    notify-send "未找到 opacity 配置"
    exit 1
fi

# 提取行号和值
line_number=$(echo "$current_line" | cut -d: -f1)
current_value=$(echo "$current_line" | cut -d= -f2 | tr -d ' ')

# 手动处理小数运算
integer_part=$(echo "$current_value" | cut -d. -f1)
decimal_part=$(echo "$current_value" | cut -d. -f2)

# 转换为整数（0.10 -> 10）
total_value=$((integer_part * 100 + 10#$decimal_part))

# 增加10%
new_total_value=$((total_value + 10))

# 如果超过100，重置为10
if [ $new_total_value -gt 100 ]; then
    new_total_value=10
fi

# 转换回小数格式
new_integer=$((new_total_value / 100))
new_decimal=$((new_total_value % 100))
new_value=$(printf "%d.%02d" $new_integer $new_decimal)

# 更新配置文件
sed -i "${line_number}s/opacity = .*/opacity = $new_value/" "$CONFIG_FILE"

# 显示桌面通知
notify-send "Alacritty 透明度:$new_value"
