#!/bin/bash

# 基于hyprpaper

# 壁纸目录
WALLPAPER_DIR=~/.config/hypr/bg

# 工作区与壁纸映射
declare -A wallpapers=(
    ["1"]="moon.jpg"
    ["2"]="sun.jpg"
    ["3"]="arch.png"
    ["4"]="clay.jpg"
    ["5"]="code.png"
    ["0"]="default.jpg"
)

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  数字          切换到对应工作区的预设壁纸 (0-5)"
    echo "  -r, --random  随机选择一个壁纸"
    echo "  -l, --list    显示所有可用的壁纸映射"
    echo "  -h, --help    显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 1          # 切换到工作区1的壁纸 (moon.jpg)"
    echo "  $0 3          # 切换到工作区3的壁纸 (arch.png)"
    echo "  $0 --random   # 随机选择壁纸"
    echo "  $0            # 无参数时随机选择壁纸"
}

# 显示壁纸列表
show_list() {
    echo "工作区壁纸映射:"
    for workspace in "${!wallpapers[@]}"; do
        echo "  工作区 $workspace: ${wallpapers[$workspace]}"
    done

    echo -e "\n壁纸目录 ($WALLPAPER_DIR) 中的文件:"
    if [ -d "$WALLPAPER_DIR" ]; then
        ls -1 "$WALLPAPER_DIR" | while read file; do
            echo "  $file"
        done
    else
        echo "  错误: 壁纸目录不存在: $WALLPAPER_DIR"
    fi
}

# 随机选择壁纸
set_random_wallpaper() {
    if [ -d "$WALLPAPER_DIR" ]; then
        # 获取所有图片文件
        local images=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \)))

        if [ ${#images[@]} -eq 0 ]; then
            echo "错误: 在 $WALLPAPER_DIR 中未找到图片文件"
            return 1
        fi

        # 随机选择一张图片
        local random_index=$((RANDOM % ${#images[@]}))
        local random_wallpaper="${images[$random_index]}"

        echo "随机选择壁纸: $(basename "$random_wallpaper")"
        hyprctl hyprpaper wallpaper ",$random_wallpaper"
    else
        echo "错误: 壁纸目录不存在: $WALLPAPER_DIR"
        return 1
    fi
}

# 设置指定工作区的壁纸
set_workspace_wallpaper() {
    local workspace="$1"

    if [ -n "${wallpapers[$workspace]}" ]; then
        local wallpaper_file="$WALLPAPER_DIR/${wallpapers[$workspace]}"

        if [ -f "$wallpaper_file" ]; then
            echo "切换到工作区 $workspace 的壁纸: ${wallpapers[$workspace]}"
            hyprctl hyprpaper wallpaper ",$wallpaper_file"
        else
            echo "错误: 壁纸文件不存在: $wallpaper_file"
            echo "正在随机选择壁纸..."
            set_random_wallpaper
        fi
    else
        echo "错误: 未找到工作区 $workspace 的壁纸映射"
        echo "可用的工作区: ${!wallpapers[@]}"
        return 1
    fi
}

# 主函数
main() {
    # 检查参数
    case "$1" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            show_list
            ;;
        -r|--random)
            set_random_wallpaper
            ;;
        [0-9])
            set_workspace_wallpaper "$1"
            ;;
        "")
            # 无参数，随机选择
            echo "未指定参数，随机选择壁纸..."
            set_random_wallpaper
            ;;
        *)
            echo "错误: 未知参数 '$1'"
            echo "使用 '$0 --help' 查看使用方法"
            return 1
            ;;
    esac
}

# 运行主函数
main "$@"
