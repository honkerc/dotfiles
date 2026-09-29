#!/bin/bash
# Swaybg 随机壁纸切换脚本

# ========== 配置区域 ==========
# 壁纸文件夹 1 (你的主壁纸库)
WALLPAPER_DIR1="$HOME/.config/hypr/bg"
# 壁纸文件夹 2 (可选，如果你有第二个壁纸库，请取消注释并修改路径)
# WALLPAPER_DIR2="$HOME/Pictures/Wallpapers"
# =============================

# 构建查找路径
SEARCH_DIRS=("$WALLPAPER_DIR1")
# 如果配置了第二个目录且存在，则加入查找列表
if [ -n "$WALLPAPER_DIR2" ] && [ -d "$WALLPAPER_DIR2" ]; then
    SEARCH_DIRS+=("$WALLPAPER_DIR2")
fi

# 检查目录是否存在
if [ ${#SEARCH_DIRS[@]} -eq 0 ] || [ ! -d "${SEARCH_DIRS[0]}" ]; then
    echo "[错误] 未找到有效的壁纸目录，请检查 $WALLPAPER_DIR1"
    exit 1
fi

# 收集所有图片文件
wallpaper_list=$(find "${SEARCH_DIRS[@]}" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null)

if [ -z "$wallpaper_list" ]; then
    echo "[错误] 目录中未找到任何图片文件 (jpg/png/jpeg)"
    exit 1
fi

# 随机选择一张壁纸
wallpaper=$(echo "$wallpaper_list" | shuf -n 1)

if [ -z "$wallpaper" ]; then
    echo "[错误] 随机选择壁纸失败。"
    exit 1
fi

echo "[swaybg] 切换壁纸: $wallpaper"

# 杀掉冲突的动态壁纸进程 (如 mpvpaper, hyprpaper)
pkill mpvpaper 2>/dev/null
pkill hyprpaper 2>/dev/null

# 核心步骤：杀掉旧的 swaybg 进程，等待它释放资源
pkill swaybg
sleep 0.5 # 给旧进程一点时间退出，避免画面闪烁或冲突

# 启动新的 swaybg 进程，并让它在后台独立运行
# -i 指定图片，-m fill 表示填充屏幕（保持比例裁剪，类似 cover），也可改为 fit、stretch、center、tile
swaybg -i "$wallpaper" -m fill >/dev/null 2>&1 & 
disown # 让 swaybg 完全脱离当前脚本，脚本结束后它继续存活

# 将当前壁纸路径写入缓存文件（供 Waybar 等组件读取）
CACHE_FILE="$HOME/.cache/current_wallpaper"
mkdir -p "$(dirname "$CACHE_FILE")"
echo "$wallpaper" > "$CACHE_FILE"
