#!/bin/bash
# 增强版Hyprland启动脚本 - 带加载动画

function set_wayland_env() {
    cd ${HOME}

    # 输入法环境
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    export SDL_IM_MODULE=fcitx
    export GLFW_IM_MODULE=ibus
    
    # 语言环境
    export LANG=en_US.UTF-8
    
    # QT 设置
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export QT_QPA_PLATFORMTHEME=qt5ct
    
    # SDL 和 GTK
    export SDL_VIDEODRIVER=wayland
    export GDK_BACKEND="wayland,x11"
    
    # Java 黑屏修复
    export _JAVA_AWT_WM_NONEREPARENTING=1
    
    # 其他应用兼容性
    export MOZ_ENABLE_WAYLAND=1
    export ELECTRON_OZONE_PLATFORM_HINT=auto
    
    # NVIDIA 优化环境变量
    export __GL_GSYNC_ALLOWED=0
    export __GL_VRR_ALLOWED=0
    export WLR_NO_HARDWARE_CURSORS=1
    export GBM_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
}

# 启动加载动画
function start_loading_animation() {
    # 清理残留的Wayland锁文件
    rm -f /run/user/$(id -u)/wayland-*.lock
    
    # 优先尝试图形化动画 (需安装imv)
    if command -v imv >/dev/null && [ -f "$HOME/.config/hypr/loading.gif" ]; then
        imv -f -s fill "$HOME/.config/hypr/loading.gif" >/dev/null 2>&1 &
        LOAD_PID=$!
        LOAD_TYPE="graphical"
        echo "启动图形加载动画 (PID: $LOAD_PID)"
    else
        # ASCII动画回退方案
        terminal=$(command -v kitty || command -v wezterm || command -v alacritty || command -v xterm)
        $terminal --title HyprlandLoadingScreen -e bash -c '
        echo -e "\e[?25l"
        while true; do
            clear
            echo -e "\e[34m"
            echo "   ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗"
            echo "   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
            echo "   ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
            echo "   ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║"
            echo "   ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
            echo "   ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝"
            echo -e "\e[0m"
            echo "Initializing Hyprland..."
            sleep 0.5
        done' &
        LOAD_PID=$!
        LOAD_TYPE="terminal"
        echo "启动终端加载动画 (PID: $LOAD_PID)"
    fi
}

# 关闭加载动画
function stop_loading_animation() {
    if [ -n "$LOAD_PID" ]; then
        echo "正在关闭加载动画 (PID: $LOAD_PID)"
        if [ "$LOAD_TYPE" = "graphical" ]; then
            kill $LOAD_PID
            # 确保imv完全退出
            sleep 0.2
            pkill -9 imv
        elif [ "$LOAD_TYPE" = "terminal" ]; then
            # 更安全的终端关闭方式
            pkill -P $LOAD_PID
            kill $LOAD_PID
        fi
        unset LOAD_PID
        unset LOAD_TYPE
    fi
}

# 检测Hyprland是否完成启动
function is_hyprland_ready() {
    # 检查Hyprland IPC是否响应
    if ! command -v hyprctl >/dev/null; then
        echo "错误: hyprctl 命令未找到"
        return 1
    fi
    
    # 尝试获取监视器信息
    if hyprctl monitors >/dev/null 2>&1; then
        # 额外检查是否有窗口管理器运行
        if hyprctl clients | grep -q '[w]aybar\|[s]tatusbar'; then
            echo "Hyprland 已完全启动"
            return 0
        fi
    fi
    return 1
}

function start_hyprland() {
    set_wayland_env
    
    # 设置会话变量
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=Hyprland
    export XDG_CURRENT_DESKTOP=Hyprland
    
    # 启动加载动画
    start_loading_animation
    
    # 启动Hyprland后台进程
    echo "启动Hyprland..."
    Hyprland &
    HYPR_PID=$!
    
    # 等待Hyprland启动完成
    echo "等待Hyprland初始化..."
    local timeout=15  # 最大等待15秒
    while [ $timeout -gt 0 ]; do
        if is_hyprland_ready; then
            break
        fi
        sleep 1
        ((timeout--))
    done
    
    # 关闭加载动画
    stop_loading_animation
    
    # 等待Hyprland主进程退出
    echo "Hyprland PID: $HYPR_PID"
    wait $HYPR_PID
    echo "Hyprland 已退出"
}

# 主执行入口
start_hyprland
