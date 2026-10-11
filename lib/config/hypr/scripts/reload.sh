#!/bin/bash
if hyprctl reload; then
    notify-send "Hypr Config Reloaded"  # 仅在成功时发送通知
else
    notify-send "Failed to Reload Config"  # 如果失败，发送失败通知
fi

