#!/bin/sh
# 检查是否在 Alacritty 中运行
if [ "$TERM" = "alacritty" ]; then
    # 在当前终端窗口运行 Neovim（无内边距）
    alacritty msg config window.padding.x=0 window.padding.y=0
    nvim "$@"
    alacritty msg config window.padding.x=20 window.padding.y=20
else
    # 非 Alacritty 环境，直接运行 Neovim
    nvim "$@"
fi
