#!/bin/bash
# 从壁纸库随机设置工作区和概览背景壁纸（精确控制时长）

WALLPAPER_DIR="/data/bg"

# --- 工作区背景动画（极速）---
WORKSPACE_TRANSITION_TYPE="random"
WORKSPACE_TRANSITION_DURATION=0.8    # 总时长0.5秒，直接控制速度
WORKSPACE_TRANSITION_FPS=144         # 高帧率保证顺滑

# --- 概览背景动画（快速）---
BACKDROP_TRANSITION_TYPE="random"
BACKDROP_TRANSITION_DURATION=0.8     # 时长稍长，比工作区慢一点
BACKDROP_TRANSITION_FPS=144

# 检查目录
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "壁纸目录不存在: $WALLPAPER_DIR"
    exit 1
fi

# 收集壁纸
mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf)

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "未找到任何壁纸文件"
    exit 1
fi

# 确保 daemon 运行
if ! pgrep -f "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 0.5
fi
if ! pgrep -f "awww-daemon --namespace backdrop" > /dev/null; then
    awww-daemon --namespace backdrop &
    sleep 0.5
fi

# 选择壁纸
workspace_wall="${wallpapers[0]}"
if [ ${#wallpapers[@]} -gt 1 ]; then
    backdrop_wall="${wallpapers[1]}"
else
    backdrop_wall="$workspace_wall"
fi

# 设置工作区壁纸
echo "工作区: $(basename "$workspace_wall")"
awww img "$workspace_wall" \
    --transition-type "$WORKSPACE_TRANSITION_TYPE" \
    --transition-duration "$WORKSPACE_TRANSITION_DURATION" \
    --transition-fps "$WORKSPACE_TRANSITION_FPS"

# 设置概览背景壁纸
echo "概览背景: $(basename "$backdrop_wall")"
awww img -n backdrop "$backdrop_wall" \
    --transition-type "$BACKDROP_TRANSITION_TYPE" \
    --transition-duration "$BACKDROP_TRANSITION_DURATION" \
    --transition-fps "$BACKDROP_TRANSITION_FPS"

