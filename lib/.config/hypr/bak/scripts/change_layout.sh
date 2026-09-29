#!/bin/bash
# 超简版布局轮播（带通知）

layouts=("dwindle" "master" "scrolling")

# 获取当前布局
current=$(hyprctl getoption general:layout | grep "str:" | awk '{print $2}' | tr -d '"' 2>/dev/null)

# 检查 hyprctl 是否执行成功
if [ $? -ne 0 ]; then
    notify-send "布局切换错误" "无法获取当前布局" -t 3000 -u critical
    exit 1
fi

# 循环查找并切换布局
for i in "${!layouts[@]}"; do
    if [ "${layouts[$i]}" = "$current" ]; then
        next_index=$(( (i + 1) % 3 ))
        next_layout="${layouts[$next_index]}"

        # 切换布局
        if hyprctl keyword general:layout "$next_layout" 2>/dev/null; then
            notify-send "布局切换" "当前: $next_layout" -t 1500
            exit 0
        else
            notify-send "切换出错" "切换到 $next_layout 失败" -t 3000 -u critical
            exit 1
        fi
    fi
done

# 如果没找到当前布局，切换到第一个
if hyprctl keyword general:layout "${layouts[0]}" 2>/dev/null; then
    notify-send "布局切换" "当前: ${layouts[0]}" -t 1500
else
    notify-send "切换出错" "切换到 ${layouts[0]} 失败" -t 3000 -u critical
    exit 1
fi
