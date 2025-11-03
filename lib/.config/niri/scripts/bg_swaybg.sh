#!/bin/bash
# Swaybg 壁纸随机切换脚本 - 绝对路径版

# 设置壁纸目录
BG_PATH="/data/bg/img"

# 杀死现有的 swaybg 进程
pkill swaybg

# 等待进程完全终止
# sleep 0.5

# 随机选择一张壁纸
wallpaper=$(find "$BG_PATH" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    echo "[Swaybg] 切换壁纸: $(basename "$wallpaper")"
    # 使用绝对路径执行 swaybg
    /usr/bin/swaybg -i "$wallpaper" -m fill &
else
    echo "[错误] 未找到有效壁纸文件"
    # 使用默认颜色作为后备
    /usr/bin/swaybg -c "#2e3440" &
fi