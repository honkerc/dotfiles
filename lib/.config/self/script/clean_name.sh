#!/bin/bash

# 文件名清理脚本
# 将文件名中的特殊字符转换为下划线

clean_filename() {
    local filename="$1"

    # 去除前后空格
    filename=$(echo "$filename" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 定义要替换的特殊字符
    local replacements=(
        's/ /_/g'
        's/(/_/g'
        's/)/_/g'
        's/\[/_/g'
        's/\]/_/g'
        's/{/_/g'
        's/}/_/g'
        's/</_/g'
        's/>/_/g'
        's/,/_/g'
        's/;/_/g'
        's/:/_/g'
        's/!/_/g'
        's/?/_/g'
        's/@/_/g'
        's/#/_/g'
        's/\$/_/g'
        's/%/_/g'
        's/\^/_/g'
        's/&/_/g'
        's/\*/_/g'
        's/=/_/g'
        's/+/_/g'
        's/|/_/g'
        's/~/_/g'
        's/`/_/g'
        's/"/_/g'
        "s/'/_/g"
        's/\\/_/g'
        's/\//_/g'
    )

    # 应用所有替换规则
    for pattern in "${replacements[@]}"; do
        filename=$(echo "$filename" | sed "$pattern")
    done

    # 处理多个连续的下划线
    filename=$(echo "$filename" | sed 's/__\+/_/g')

    # 去除开头和结尾的下划线
    filename=$(echo "$filename" | sed 's/^_*//;s/_*$//')

    # 如果文件名为空，使用默认名称
    if [ -z "$filename" ]; then
        filename="unnamed_file"
    fi

    echo "$filename"
}

rename_files() {
    local dir="${1:-.}"

    # 使用 find 递归查找所有文件和目录
    while IFS= read -r -d '' item; do
        if [ -e "$item" ]; then
            local dirname=$(dirname "$item")
            local basename=$(basename "$item")
            local cleaned_name=$(clean_filename "$basename")

            # 如果清理后的名称不同，则重命名
            if [ "$basename" != "$cleaned_name" ]; then
                local new_path="$dirname/$cleaned_name"

                # 检查目标文件是否已存在
                if [ -e "$new_path" ]; then
                    echo "警告: 文件已存在，跳过: $new_path"
                else
                    echo "重命名: '$basename' -> '$cleaned_name'"
                    mv "$item" "$new_path"
                fi
            fi
        fi
    done < <(find "$dir" -depth -print0)
}

# 主函数
main() {
    local target_dir="${1:-.}"

    echo "开始清理文件名中的特殊字符..."
    echo "目标目录: $target_dir"
    echo "======================================"

    # 检查目录是否存在
    if [ ! -d "$target_dir" ]; then
        echo "错误: 目录不存在: $target_dir"
        exit 1
    fi

    # 确认操作
    read -p "确定要重命名目录 '$target_dir' 中的所有文件吗？(y/N): " confirm
    case "$confirm" in
        [yY]|[yY][eE][sS])
            echo "开始处理..."
            ;;
        *)
            echo "操作已取消"
            exit 0
            ;;
    esac

    # 执行重命名
    rename_files "$target_dir"

    echo "======================================"
    echo "文件名清理完成！"
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [目录路径]"
    echo "如果没有指定目录，默认使用当前目录"
    echo ""
    echo "示例:"
    echo "  $0                    # 清理当前目录"
    echo "  $0 /path/to/dir       # 清理指定目录"
    echo "  $0 ~/Documents        # 清理家目录下的Documents文件夹"
}

# 检查参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# 执行主函数
main "$@"
