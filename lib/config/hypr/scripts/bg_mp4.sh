#!/bin/bash
# 随机选择MP4文件作为mpvpaper动态壁纸脚本
# 使用说明：保存为 random_wallpaper.sh 后执行 chmod +x random_wallpaper.sh

# 配置参数（按需修改）
WALLPAPER_DIR="/data/bg/mp4"   # 壁纸目录
SCREEN_NAME="eDP-1"           # 显示器名称（通过xrandr查看）
LOG_FILE="/tmp/mpvpaper_wallpaper.log"  # 日志文件路径

# 记录日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查目录是否存在
if [ ! -d "$WALLPAPER_DIR" ]; then
    log "错误：目录 $WALLPAPER_DIR 不存在！"
    exit 1
fi

# 获取MP4文件列表（排除子目录）
mapfile -t VIDEO_FILES < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -name "*.mp4" 2>/dev/null)

# 检查文件数量
if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
    log "错误：目录中未找到MP4文件！"
    exit 2
fi

# 随机选择文件（使用shuf命令）
RANDOM_INDEX=$((RANDOM % ${#VIDEO_FILES[@]}))
SELECTED_FILE="${VIDEO_FILES[$RANDOM_INDEX]}"
log "已选择文件：$SELECTED_FILE"

# 关闭现有mpvpaper进程
pkill mpvpaper
pkill swaybg
sleep 0.2  # 等待进程释放

# 启动新壁纸（带硬件加速和静音）
#if mpvpaper -o "loop --profile=low-latency --no-audio" "$SCREEN_NAME" "$SELECTED_FILE" &>> "$LOG_FILE"; then
if mpvpaper -o "loop --hwdec=vaapi --profile=low-latency --no-audio" "$SCREEN_NAME" "$SELECTED_FILE" &>> "$LOG_FILE"; then
    log "壁纸启动成功！"
else
    log "壁纸启动失败！尝试备用方案..."
    # 备用方案（无硬件加速）
    mpvpaper -o "loop --no-audio" "$SCREEN_NAME" "$SELECTED_FILE" &>> "$LOG_FILE"
fi
