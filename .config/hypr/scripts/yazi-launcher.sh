#!/bin/bash

# 检查是否在终端中运行
if [ -t 1 ]; then
    # 在终端环境中，直接运行 yazi 并处理目录切换
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    yazi "$PWD" --cwd-file="$tmp"

    if [ -f "$tmp" ]; then
        cwd=$(cat "$tmp")
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd "$cwd"
        fi
        rm -f "$tmp"
    fi
else
    # 不在终端环境中，使用终端打开 yazi
    # 检测可用的终端
    if command -v kitty >/dev/null 2>&1; then
        kitty --single-instance yazi "$PWD"
    elif command -v alacritty >/dev/null 2>&1; then
        alacritty -e yazi "$PWD"
    elif command -v foot >/dev/null 2>&1; then
        foot yazi "$PWD"
    elif command -v wezterm >/dev/null 2>&1; then
        wezterm start --cwd "$PWD" yazi
    elif command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- yazi "$PWD"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal -e "yazi $PWD"
    else
        # 最后尝试使用 xterm
        xterm -e yazi "$PWD"
    fi
fi
