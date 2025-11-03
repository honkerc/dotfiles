#!/bin/bash

# 简洁版 v2raya 切换脚本

SERVICE_NAME="v2raya"

# 通知函数
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  # 默认普通优先级

    # 检查是否有桌面环境并发送通知
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$message" -u "$urgency"
    else
        echo "注意: 未找到 notify-send 命令，无法发送桌面通知"
    fi
}

if systemctl is-active --quiet "$SERVICE_NAME"; then
    pkexec systemctl stop "$SERVICE_NAME"
    echo "[+] v2raya 已停止"
    notify "v2raya 状态" "v2raya 服务已停止" "normal"
else
    pkexec systemctl start "$SERVICE_NAME"
    echo "[+] v2raya 已启动"
    notify "v2raya 状态" "v2raya 服务已启动" "normal"
fi
