-- =============================================================================
-- 自动启动配置（对应原 exec.conf）
-- hl.on("hyprland.start", ...) 内的命令仅在 Hyprland 首次启动时执行一次
-- 等价于原 exec-once = ...
-- =============================================================================

hl.on("hyprland.start", function()

    -- ── 插件管理器 ────────────────────────────────────────────────────────
    -- 重新加载 hyprpm 插件（-n = 不显示通知）
    hl.exec_cmd("hyprpm reload")

    -- ── 壁纸程序 ──────────────────────────────────────────────────────────
    -- hyprpaper：读取 ~/.config/hypr/hyprpaper.conf 配置
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/bg.sh ")

    -- ── 输入法 ────────────────────────────────────────────────────────────
    -- fcitx5：中文输入法框架，-d 以守护进程方式运行
    hl.exec_cmd("fcitx5 -d")

    -- ── 网络管理 ──────────────────────────────────────────────────────────
    -- nm-applet：NetworkManager 系统托盘图标
    hl.exec_cmd("nm-applet")

    -- ── 状态栏 ────────────────────────────────────────────────────────────
    -- 如需启用 waybar，取消下方注释
    hl.exec_cmd("waybar -c " .. os.getenv("HOME") .. "/.config/waybar/config -s " .. os.getenv("HOME") .. "/.config/waybar/style.css")

    -- ── 通知守护进程 ──────────────────────────────────────────────────────
    -- dunst：轻量级桌面通知程序
    hl.exec_cmd("dunst")

    -- ── 图形认证代理 ──────────────────────────────────────────────────────
    -- 提供 sudo/pkexec 的图形密码弹窗支持
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- ── 指定工作区启动（示例，默认注释） ──────────────────────────────────
    -- 在工作区 1 静默启动 Chrome（不切换过去）
    -- hl.exec_cmd("[workspace 1 silent] google-chrome")
    -- 在工作区 2 静默启动终端
    -- hl.exec_cmd("[workspace 2 silent] alacritty")

end)
