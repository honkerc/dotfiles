#!/bin/bash

# 获取IPv4地址
ip=$(ip -4 address show | grep inet | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
trimmed_ip=$(echo "$ip" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# 根据参数决定输出类型
if [ $# -eq 0 ]; then
    # 无参数：返回完整IP地址
    output="$trimmed_ip"
    message="IP: $trimmed_ip"
else
    # 有参数：返回C段前缀（格式：192.168.104.）
    c_segment=$(echo "$trimmed_ip" | awk -F. '{OFS="."; $4=""; print $0}' | sed 's/\.$//'). 
    output="$c_segment"
    message="C段: $c_segment"
fi

# 复制到剪贴板
printf "$output" | wl-copy

# 发送通知
notify-send "$message"