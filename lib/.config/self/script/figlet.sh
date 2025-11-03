#!/bin/bash

# 设置字体目录
FONT_DIR="/usr/share/figlet/fonts"

# 默认文本
DEFAULT_TEXT="Worker"

# 检查字体目录是否存在
if [ ! -d "$FONT_DIR" ]; then
    echo -e "\033[31m错误: 字体目录 $FONT_DIR 不存在\033[0m"
    exit 1
fi

# 获取所有字体文件
fonts=("$FONT_DIR"/*.flf)

# 检查是否有字体文件
if [ ${#fonts[@]} -eq 0 ]; then
    echo -e "\033[31m错误: 在 $FONT_DIR 中找不到任何字体文件 (.flf)\033[0m"
    exit 1
fi

# 颜色数组
colors=("1;31" "1;32" "1;33" "1;34" "1;35" "1;36")
color_index=0

echo -e "\033[1;37m开始显示所有字体效果...\033[0m"
echo -e "\033[1;37m默认文本: '$DEFAULT_TEXT'\033[0m"
echo -e "\033[1;37m共 ${#fonts[@]} 种字体\033[0m"
echo

# 遍历所有字体
for font in "${fonts[@]}"; do
    # 获取字体文件名（不含路径）
    font_name=$(basename "$font")

    # 显示字体名称
    echo -e "\033[1;37m字体: \033[1;33m$font_name\033[0m"

    # 设置颜色
    color_code=${colors[$color_index]}
    echo -e "\033[${color_code}m"

    # 使用当前字体显示默认文本
    figlet -d "$FONT_DIR" -f "$font_name" "$DEFAULT_TEXT" 2>/dev/null

    # 重置颜色
    echo -e "\033[0m"

    # 更新颜色索引
    color_index=$(( (color_index + 1) % ${#colors[@]} ))

    # 添加分隔线
    echo "----------------------------------------"
done

echo -e "\033[1;32m所有字体展示完毕！共展示了 ${#fonts[@]} 种字体。\033[0m"
