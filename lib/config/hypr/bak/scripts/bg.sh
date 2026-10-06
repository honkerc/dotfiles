#!/bin/bash
# Hyprpaper 壁纸随机切换脚本 (从两个固定文件夹随机)

# ========== 配置区域 ==========
# 请修改为你的两个壁纸文件夹实际路径
WALLPAPER_DIR1="$HOME/.config/hypr/bg"
WALLPAPER_DIR2="$BG_PATH"
# =============================

# 确保 hyprpaper 进程在运行（防止崩溃后无响应）
if ! pgrep -x "hyprpaper" >/dev/null; then
    hyprpaper &
    sleep 1
fi

# 从两个文件夹收集所有图片文件（带完整路径）
wallpaper_list=$(find "$WALLPAPER_DIR1" "$WALLPAPER_DIR2" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null)

# 检查是否找到文件
if [ -z "$wallpaper_list" ]; then
    echo "[错误] 未找到任何壁纸文件，请检查目录: $WALLPAPER_DIR1 和 $WALLPAPER_DIR2"
    exit 1
fi

# 随机选择一张壁纸（跳过无效文件）
while true; do
    wallpaper=$(echo "$wallpaper_list" | shuf -n 1)

    if file -b --mime-type "$wallpaper" | grep -qE 'image/(jpeg|png)'; then
        echo "[Hyprpaper] 切换壁纸: $wallpaper"
        break
    else
        echo "[警告] 跳过无效文件: $wallpaper"
    fi
done

# 杀死可能冲突的进程
pkill mpvpaper 2>/dev/null

# 直接设置壁纸（hyprpaper 0.8+ 会自动加载）
if [ -n "$wallpaper" ]; then
    hyprctl hyprpaper wallpaper ",$wallpaper"
    export BG="$wallpaper"
else
    echo "[错误] 未找到有效壁纸，请检查目录: $WALLPAPER_DIR1 和 $WALLPAPER_DIR2"
fi
