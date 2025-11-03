#!/bin/sh

# 检查是否在 Kitty 中运行
if [ -n "$KITTY_WINDOW_ID" ] || [ "$TERM" = "xterm-kitty" ]; then
    # 保存当前边距设置
    current_margin=$(kitty @ get-spacing 2>/dev/null | grep -oP 'margin:\s*\K[0-9]+' || echo "20")

    # 设置无边距
    kitty @ set-spacing margin=0

    # 运行 Neovim
    nvim "$@"

    # 恢复原来的边距
    kitty @ set-spacing margin=$current_margin

# 检查是否在 Alacritty 中运行
elif [ "$TERM" = "alacritty" ] || [ -n "$ALACRITTY_WINDOW_ID" ]; then
    # 在当前终端窗口运行 Neovim（无内边距）
    alacritty msg config window.padding.x=0 window.padding.y=0
    nvim "$@"
    alacritty msg config window.padding.x=20 window.padding.y=20

else
    # 非 Kitty 或 Alacritty 环境，直接运行 Neovim
    nvim "$@"
fi
