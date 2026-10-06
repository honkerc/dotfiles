#!/bin/sh
if [ "$NVIM_MODE" = "true" ]; then
    # 启动 Neovim 时移除内边距
    alacritty -o "window.padding.x=0" -o "window.padding.y=0" -e nvim "$@"
else
    # 其他命令使用默认配置
    exec "$@"
fi
