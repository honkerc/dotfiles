#!/bin/bash
# Hyprpaper 壁纸随机切换脚本 (修复版)

# 确保 hyprpaper 进程在运行（防止崩溃后无响应）
if ! pgrep -x "hyprpaper" >/dev/null; then
    hyprpaper &  # 后台启动 hyprpaper
    sleep 1    # 等待进程初始化
fi

# 释放内存中的壁纸
hyprctl hyprpaper unload all

# 随机选择一张壁纸（跳过无效文件）
while true; do
    wallpaper=$(find "$BG_PATH" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)

    # 检查文件有效性（通过文件头识别真实格式）
    if file -b --mime-type "$wallpaper" | grep -qE 'image/(jpeg|png)'; then
        echo "[Hyprpaper] 切换壁纸: $wallpaper"
        break
    else
        echo "[警告] 跳过无效文件: $wallpaper"
    fi
done

# 杀死可能冲突的进程
pkill mpvpaper 2>/dev/null

# 安全加载壁纸
if [ -n "$wallpaper" ]; then
    # 预加载壁纸（捕获错误信息）
    if ! hyprctl hyprpaper preload "$wallpaper" 2>&1 | grep -q "error"; then
        # 设置壁纸
        hyprctl hyprpaper wallpaper ",$wallpaper"
        exprort $BG = $wallpaper
    else
        echo "[错误] 加载失败，请检查文件: $wallpaper"
    fi
else
    echo "[错误] 未找到有效壁纸，请检查目录: $BG_PATH"
fi
