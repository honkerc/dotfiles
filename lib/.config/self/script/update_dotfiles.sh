#!/bin/bash

# 增强版配置文件备份脚本（带序号、颜色输出和选择性日志功能）
# 功能：
# 1. 将 ~/.config 下的指定配置文件复制到目标备份目录
# 2. 执行用户定义的任务列表并报告结果
# 3. 带有序号提示和彩色输出
# 4. 仅在失败时记录错误信息到日志文件（简化格式）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 重置颜色

# 日志文件设置（仅在错误时创建）
LOG_FILE="${HOME}/backup_script.log"
LOG_CONTENT=""  # 用于累积错误信息

# 源目录 (用户配置目录)
SOURCE_DIR="$HOME/.config"

# 目标备份目录
DOTFILE_DIR="$DOTFILES"
CONFIF_DIR="${1:-$DOTFILE_DIR/.config}"

# 需要备份的配置文件列表
BACKUP_FILES=(
    "alacritty"     # Alacritty终端
    "cava"          # cava音乐音效效果
    "dunst"         # 通知管理
    "fcitx5"        # 输入法相关配置
    "nvim"          # neovim配置
    "yazi"          # 文件管理器
    "hypr"          # hyprland窗口管理器配置文件
    "waybar"        # 状态栏
    "rofi"          # rofi启动器
    "self"          # 自定义配置
    "pip"           # pip源
    "kitty"         # kitty源
    "niri"         # kitty源
    "fish"          # fish
)

# 执行任务列表（用户可以自定义添加/删除）
# 如果操作比较复杂建议新建功能函数去执行，如copy_grub_theme


# 额外需要复制的内容

copy_grub_theme() {
    local source_dir="/boot/grub/themes/simple"
    local target_dir="$DOTFILE_DIR/grub"
    local func_name="${FUNCNAME[0]}"

    # 检查源目录是否存在

    if [ ! -d "$source_dir" ]; then
        add_log "$func_name" "$source_dir 不存在"
        return 1

    fi

    # 使用 diff 检查目录差异
    if diff -rq "$source_dir" "$target_dir" >/dev/null 2>&1; then
        return 0
    fi


    # 准备执行命令
    local cmd="rm -fr '$target_dir' && \
               cp -rf '$source_dir' '$target_dir' && \
               chown -R $(id -u):$(id -g) '$target_dir'"

    # 执行命令并捕获输出
    local output
    output=$(pkexec bash -c "$cmd" 2>&1)

    local status=$?

    # 处理执行结果
    if [ $status -eq 0 ]; then
        return 0

    # 执行失败?
    else
        # 添加日志
        add_log "$func_name： $cmd" "执行失败: $output"
        return 1
    fi
}

# 在任务命令中使用
declare -A task_commands
# task_commands["复制.zshrc文件"]="cp -rf $HOME/.zshrc $DOTFILE_DIR/"
# task_commands["复制pacman.config"]="sudo cp /etc/pacman.conf $DOTFILE_DIR/"
task_commands["复制grub主题"]="copy_grub_theme"
# task_commands["复制oh-my-zsh主题"]="cp $HOME/.oh-my-zsh/themes/nicoulaj.zsh-theme $CONFIF_DIR/"
# task_commands["更改权限"]=""

# 添加错误日志函数（简化格式）
add_log() {
    local command="$1"
    local error="$2"
    LOG_CONTENT+="- [命令]${command}\n  [信息]${error}\n"
}

# 执行开始
echo -e "${CYAN}=======================================${NC}"
echo -e "${BLUE}目标地址:${NC} $DOTFILE_DIR"
echo -e "${BLUE}Config地址:${NC} $CONFIF_DIR"
echo -e "${CYAN}=======================================${NC}"
echo

# 删除旧文件
rm -fr "$DOTFILE_DIR/.config" "$DOTFILE_DIR/.zshrc" "$DOTFILE_DIR/grub"
# 创建目标目录（如果不存在）
mkdir -p "$DOTFILE_DIR" 2>/dev/null || {
    error_msg="无法创建目录: $DOTFILE_DIR"
    echo -e "${RED}$error_msg${NC}"
    add_log "mkdir -p $DOTFILE_DIR" "$error_msg"
}
mkdir -p "$CONFIF_DIR" 2>/dev/null || {
    error_msg="无法创建目录: $CONFIF_DIR"
    echo -e "${RED}$error_msg${NC}"
    add_log "mkdir -p $CONFIF_DIR" "$error_msg"
}

# 备份计数器
success_count=0
fail_count=0

total_backup=${#BACKUP_FILES[@]}
echo -e "${MAGENTA}开始备份配置文件到: $CONFIF_DIR${NC}"
echo -e "${CYAN}--------------------------------${NC}"

# 遍历并复制每个配置文件
for ((i=0; i<total_backup; i++)); do
    file="${BACKUP_FILES[$i]}"
    source_path="$SOURCE_DIR/$file"
    target_path="$CONFIF_DIR/$file"
    target_dir=$(dirname "$target_path")

    # 创建目标目录结构
    mkdir -p "$target_dir" 2>/dev/null || {
        error_msg="无法创建目录: $target_dir"
        echo -e "${RED}$error_msg${NC}"
        add_log "mkdir -p $target_dir" "$error_msg"
        ((fail_count++))
        continue
    }

    # 显示带序号的进度
    echo -ne "[$((i+1))/$total_backup] 备份: ${BLUE}$file${NC}... "

    if [[ -e "$source_path" ]]; then
        # 尝试普通用户复制
        if cp -rf "$source_path" "$target_path" 2>/dev/null; then
            echo -e "${GREEN}成功${NC}"
            ((success_count++))
        else
            # 捕获错误信息
            error_output=$(cp -rfv "$source_path" "$target_path" 2>&1 | tr '\n' ' ')

            # 尝试sudo复制
            echo -ne "${YELLOW}失败 (尝试使用sudo)... ${NC}"
            if sudo cp -rf "$source_path" "$target_path" 2>/dev/null; then
                echo -e "${GREEN}成功 (使用sudo)${NC}"
                ((success_count++))
                sudo chown -R $USER:$USER "$target_path" 2>/dev/null
            else
                sudo_error=$(sudo cp -rfv "$source_path" "$target_path" 2>&1 | tr '\n' ' ')
                echo -e "${RED}失败 (权限问题)${NC}"
                add_log "cp -rf $source_path $target_path" "$error_output"
                add_log "sudo cp -rf $source_path $target_path" "$sudo_error"
                ((fail_count++))
            fi
        fi
    else
        echo -e "${YELLOW}跳过 (源文件不存在)${NC}"
        add_log "检查源文件存在" "源文件不存在: $source_path"
        ((fail_count++))
    fi
done

# 显示备份报告
echo
echo -e "${CYAN}备份完成 ${GREEN}成功: $success_count${NC}, ${RED}失败: $fail_count${NC}"

# 执行额外任务
echo
total_tasks=${#task_commands[@]}
echo -e "${MAGENTA}开始执行额外任务 ($total_tasks 项)${NC}"
echo -e "${CYAN}--------------------------------${NC}"
task_success=0
task_fail=0
i=0

# 遍历并执行每个任务
for task_desc in "${!task_commands[@]}"; do
    cmd="${task_commands[$task_desc]}"

    # 显示带序号的进度
    echo -ne "[$((i+1))/$total_tasks] ${BLUE}$task_desc${NC}... "

    # 执行命令并捕获错误
    error_output=$(eval "$cmd" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}成功${NC}"
        ((task_success++))
    else
        # 简化错误信息为单行
        error_single_line=$(echo "$error_output" | tr '\n' ' ')
        echo -e "${RED}失败${NC}"
        add_log "$cmd" "$error_single_line"
        ((task_fail++))
    fi

    ((i++))
done

# 显示任务执行报告
echo
echo -e "${CYAN}任务执行完成 ${GREEN}成功: $task_success${NC}, ${RED}失败: $task_fail${NC}"

# 发送桌面通知汇总
if command -v notify-send &> /dev/null; then
    notify_msg="备份: $success_count 成功, $fail_count 失败\n任务: $task_success 成功, $task_fail 失败"

    if [[ $fail_count -eq 0 && $task_fail -eq 0 ]]; then
        notify-send -i dialog-information "配置更新完成" "$notify_msg"
    else
        notify-send -i dialog-warning "配置更新部分完成" "$notify_msg"
    fi
fi

# 仅在出现错误时写入日志文件
if [ -n "$LOG_CONTENT" ]; then
    echo -e "=== 备份脚本错误日志 ($(date)) ===\n" > "$LOG_FILE"
    echo -e "$LOG_CONTENT" >> "$LOG_FILE"
fi

# 最终总结
if [ $fail_count -eq 0 ] && [ $task_fail -eq 0 ]; then
    echo -e "\n${GREEN}所有操作均成功完成，未产生错误日志${NC}"
else
    echo -e "\n${RED}错误日志: ${LOG_FILE}${NC}"

    notify-send -i dialog-warning "产生错误通知" "更新过程部分出错，已产生错误日志"
fi
