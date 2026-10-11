#!/bin/bash

# 初始化规则数组
rules=(
    "dir:$HOME/.config/self/script"
    "desktop:/usr/share/applications"
    "desktop:$HOME/.local/share/applications"
)

# 样式配置
export FZF_DEFAULT_OPTS="
  --color=spinner:#F2D5CF                # 加载动画（旋转图标）颜色
  --color=hl:#5af78e                     # 非选中项的匹配关键词高亮色
  --color=fg:#C6D0F5                     # 常规文本颜色（未选中项）
  --color=header:#E78284                 # 标题栏颜色（显示结果统计信息）
  --color=info:#CA9EE6                   # 辅助信息颜色（如快捷键提示）
  --color=pointer:#ff5c57                # 光标指示符颜色（❯ 符号）
  --color=marker:#BABBF1                 # 多选模式标记符号颜色（✓ 图标）
  --color=fg+:#ff5c57                    # 选中项的文本颜色
  --color=prompt:#CA9EE6                 # 输入提示符颜色（如 > 符号）
  --color=hl+:#5af78e                    # 选中项内的匹配关键词高亮色
  --color=selected-bg:#51576D            # 多选模式下已标记项的背景色
  --color=label:#C6D0F5                  # 多选模式标签文字颜色
  --color=bg+:#414559                    # 背景色：bg+为选中项背景色
  --tabstop=1                            # 指针单字符宽度
  --info=inline-right                    # 底部右侧显示计数
  --prompt='  '                          # 简洁提示符
  --margin=0%,0%
  --padding=2%,0%,0%,0%
  --ansi                                 # 支持ANSI颜色
"

# 创建临时数组用于存储所有选项
all_options=()

# 处理rules数组中的每个项目
for item in "${rules[@]}"; do
  if [[ "$item" == dir:* ]]; then
    # 处理目录规则
    dir_path="${item#dir:}"
    # 扩展波浪号路径
    dir_path=$(eval echo "$dir_path")

    # 检查目录是否存在
    if [[ -d "$dir_path" ]]; then
      # 遍历目录中的所有文件
      while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
          # 获取文件名（包含后缀）
          filename=$(basename "$file")
          # 添加到选项数组
          all_options+=("$filename:$file")
        fi
      done < <(find "$dir_path" -maxdepth 1 -type f -print0 2>/dev/null)
    else
      echo "警告: 目录不存在: $dir_path" >&2
    fi
  elif [[ "$item" == desktop:* ]]; then
    # 处理桌面文件规则
    dir_path="${item#desktop:}"
    # 扩展波浪号路径
    dir_path=$(eval echo "$dir_path")

    # 检查目录是否存在
    if [[ -d "$dir_path" ]]; then
      # 遍历目录中的所有.desktop文件
      while IFS= read -r -d '' file; do
        if [[ -f "$file" && "$file" == *.desktop ]]; then
          # 从.desktop文件中提取Name字段
          name=$(grep -E "^Name=" "$file" | head -n 1 | cut -d= -f2)

          # 如果Name字段不存在，使用文件名（不含扩展名）
          if [[ -z "$name" ]]; then
            name=$(basename "$file" .desktop)
          fi
          
          # 添加.desktop后缀到显示名称
          name="$name.desktop"

          # 添加到选项数组
          all_options+=("$name:$file")
        fi
      done < <(find "$dir_path" -maxdepth 1 -type f -name "*.desktop" -print0 2>/dev/null)
    else
      echo "警告: 目录不存在: $dir_path" >&2
    fi
  else
    # 直接添加普通应用项
    all_options+=("$item")
  fi
done

# 使用fzf选择应用
choice=$(printf "%s\n" "${all_options[@]}" | cut -d: -f1 | fzf --prompt="  ")

if [ -n "$choice" ]; then
    # 获取对应的命令
    cmd=$(printf "%s\n" "${all_options[@]}" | grep "^$choice:" | cut -d: -f2-)

    # 检查是否是.desktop文件
    if [[ "$cmd" == *.desktop ]]; then
        # 使用gtk-launch或xdg-open启动.desktop文件
        if command -v gtk-launch >/dev/null 2>&1; then
            # 提取.desktop文件名（不含路径和扩展名）
            desktop_file=$(basename "$cmd" .desktop)
            setsid sh -c "gtk-launch $desktop_file >/dev/null 2>&1 &"
        else
            # 回退到使用xdg-open
            setsid sh -c "xdg-open \"$cmd\" >/dev/null 2>&1 &"
        fi
    else
        # 扩展波浪号路径（如果有）
        cmd=$(eval echo "$cmd")

        # 执行应用，完全从终端分离
        setsid sh -c "$cmd >/dev/null 2>&1 &"
    fi
fi
