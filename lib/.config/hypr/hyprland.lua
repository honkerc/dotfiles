-- =============================================================================
-- Hyprland 主配置文件（Lua 版本）
-- Hyprland 0.55+ 开始使用 ~/.config/hypr/hyprland.lua 作为主配置
-- 若此文件存在，hyprland.conf 将被自动忽略
-- 参考文档: https://wiki.hypr.land/Configuring/Start/
-- =============================================================================

-- ─── 加载子模块 ─────────────────────────────────────────────────────────────
-- require 会在配置目录（~/.config/hypr/）中查找对应 .lua 文件
require("autostart")  -- 自动启动程序（对应原 exec.conf）
require("keybinds")   -- 键盘快捷键（对应原 keybinds.conf）
-- require("./plugins/*")    -- 插件配置（对应原 plugins.conf）
-- require("rules")      -- 窗口规则（对应原 rules.conf）
-- =============================================================================
-- 插件配置的自动加载
-- =============================================================================
local loaded_plugins = hl.get_loaded_plugins()

-- 注意这里用的是 pairs，不是 ipairs
for plugin_name, _ in pairs(loaded_plugins) do
    if type(plugin_name) == "string" then
        local config_module = "plugins." .. plugin_name
        local ok, err = pcall(require, config_module)
        if not ok then
            print("[Hyprland] 加载插件 " .. plugin_name .. " 的配置时出错: " .. tostring(err))
        end
    end
end
-- =============================================================================
-- 显示器配置
-- 参考: https://wiki.hypr.land/Configuring/Basics/Monitors/
-- =============================================================================

hl.monitor({
    output   = "eDP-1",           -- 笔记本内置显示器名称（通过 hyprctl monitors 查看）
    mode     = "1920x1080@60.01", -- 分辨率 × 刷新率
    position = "0x0",             -- 屏幕原点位置（多显示器时按需调整）
    scale    = 1.0,               -- 缩放比例（HiDPI 可设为 1.5 或 2.0）
})


-- =============================================================================
-- 环境变量
-- 参考: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- =============================================================================

-- Wayland 后端（优先 Wayland，兼容 X11 回退）
hl.env("CLUTTER_BACKEND",                  "wayland")
hl.env("GDK_BACKEND",                      "wayland,x11,*")
hl.env("GDK_DPI_SCALE",                    "1")
hl.env("GDK_SCALE",                        "1")

-- Qt 应用 Wayland 适配
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",      "1")
hl.env("QT_QPA_PLATFORM",                  "wayland;xcb")  -- 优先 Wayland，回退 xcb
hl.env("QT_QPA_PLATFORMTHEME",             "qt5ct")        -- 使用 qt5ct 管理 Qt 主题
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")         -- 禁用 Qt 原生标题栏

-- SDL 应用使用 Wayland 后端
hl.env("SDL_VIDEODRIVER", "wayland")

-- 光标主题与大小
hl.env("XCURSOR_SIZE",       "30")
hl.env("HYPRCURSOR_THEME",   "future-cyan-hyprcursor")
hl.env("HYPRCURSOR_SIZE",    "30")


-- =============================================================================
-- 调试配置
-- 参考: https://wiki.hypr.land/Configuring/Basics/Variables/#debug
-- =============================================================================

hl.config({
    debug = {
        disable_logs      = false, -- 保留日志文件（方便排查问题）
        enable_stdout_logs = true,  -- 同时输出日志到标准输出
    },
})


-- =============================================================================
-- 外观：通用布局参数
-- 参考: https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- =============================================================================

hl.config({
    general = {
        gaps_in     = 3,  -- 相邻窗口之间的间距（像素）
        gaps_out    = 4,  -- 窗口与屏幕边缘之间的间距（像素）
        border_size = 0,  -- 窗口边框宽度，0 = 无边框

        -- 窗口边框颜色（支持纯色或渐变）
        col = {
            -- 活动窗口边框：青色到绿色的 45° 渐变
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            -- 非活动窗口边框：半透明灰色
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false, -- 是否允许拖动边框/间隙调整窗口大小
        allow_tearing    = false, -- 是否允许画面撕裂（需配合窗口规则使用）
        layout           = "scrolling", -- 默认布局: scrolling | dwindle | master
    },
})


-- =============================================================================
-- 滚动布局（Scrolling Layout）专项配置
-- 参考: https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- =============================================================================

hl.config({
    scrolling = {
        focus_fit_method        = 0,    -- 焦点适配方式（0 = 自动居中）
        fullscreen_on_one_column = true, -- 当只有一列时，窗口占满屏幕
        column_width            = 0.8,  -- 列宽比例（1.0 = 全屏宽度）
    },
})


-- =============================================================================
-- 外观：窗口装饰（圆角、透明度、模糊）
-- 参考: https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- =============================================================================

hl.config({
    decoration = {
        rounding         = 10,  -- 窗口圆角半径（像素），0 = 直角
        active_opacity   = 1.0, -- 活动窗口的不透明度（1.0 = 完全不透明）
        inactive_opacity = 1.0, -- 非活动窗口的不透明度

        -- 毛玻璃模糊效果
        blur = {
            enabled  = true,  -- 关闭模糊（开启会增加 GPU 消耗）
            size     = 3,      -- 模糊半径（像素）
            passes   = 1,      -- 模糊遍数（值越大越模糊，消耗越高）
            vibrancy = 0.1696, -- 色彩活力增强系数
        },
    },
})


-- =============================================================================
-- 动画配置
-- 参考: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- =============================================================================

hl.config({
    animations = {
        enabled = true, -- 启用所有动画
    },
})

-- 自定义贝塞尔曲线（控制动画速度节奏）
-- 格式：hl.curve(名称, { type = "bezier", points = { {x1,y1}, {x2,y2} } })
-- 对应原 bezier = myBezier, 0.05, 0.9, 0.1, 1.05
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

-- 各类动画（leaf = 动画目标，speed = 速度，bezier = 使用的曲线）
-- hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
-- hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
-- hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
-- hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
-- hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
-- hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })
-- hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "default", style = "fade" })
--
-- -- =============================================================================
-- -- Dwindle 布局配置（二叉树瓷砖布局）
-- 参考: https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
-- =============================================================================

hl.config({
    dwindle = {
        preserve_split = true, -- 保留分割方向，防止布局跳变（推荐开启）
    },
})


-- =============================================================================
-- Master 布局配置（主从窗口布局）
-- 参考: https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
-- =============================================================================

hl.config({
    master = {
        new_status = "master", -- 新建窗口默认成为主窗口（而非 slave）
    },
})


-- =============================================================================
-- 杂项（misc）配置
-- 参考: https://wiki.hypr.land/Configuring/Basics/Variables/#misc
-- =============================================================================

hl.config({
    misc = {
        force_default_wallpaper  = 1,    -- 壁纸模式（1 = 启用默认壁纸）
        disable_hyprland_logo    = true, -- 禁用 Hyprland 内置 logo 壁纸
        disable_splash_rendering = true, -- 禁用启动 splash 画面
        key_press_enables_dpms   = true, -- 按任意键唤醒熄屏
        mouse_move_enables_dpms  = true, -- 鼠标移动时唤醒熄屏
        animate_manual_resizes   = true, -- 手动拖动调整窗口大小时显示动画
        enable_swallow           = false,-- 窗口吞咽（关闭：终端打开应用后终端消失）
        focus_on_activate        = true, -- 应用请求激活时自动获得焦点
        vrr                      = 2,    -- 可变刷新率模式（0=关 1=全局 2=游戏全屏）
    },
})


-- =============================================================================
-- 输入配置（键盘、鼠标、触摸板）
-- 参考: https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- =============================================================================

hl.config({
    input = {
        -- 键盘布局配置
        kb_layout  = "us", -- 键盘布局（"us" = 美式英语）
        kb_variant = "",   -- 布局变体（留空使用默认）
        kb_model   = "",   -- 键盘型号
        kb_options = "",   -- 额外选项（如 "ctrl:swap_lalt_lctl" 交换按键）
        kb_rules   = "",   -- XKB 规则文件

        repeat_delay = 300, -- 长按按键后开始重复前的延迟（毫秒）
        repeat_rate  = 30,  -- 按键重复速率（次/秒）

        follow_mouse = 1,   -- 焦点跟随鼠标（1=严格跟随 2=宽松跟随）
        sensitivity  = 0,   -- 鼠标加速灵敏度（0=不修改，-1.0 到 1.0）

        -- 触摸板配置
        touchpad = {
            natural_scroll = false, -- 自然滚动方向（false = 传统方向）
        },
    },
})


-- =============================================================================
-- 设备特定配置（针对某个外设单独设置参数）
-- 参考: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
-- 通过 `hyprctl devices` 查看所有设备名称
-- =============================================================================

hl.device({
    name        = "epic-mouse-v1", -- 设备名称（需与 hyprctl devices 列出的一致）
    sensitivity = -0.5,            -- 该设备的灵敏度偏移（-1.0 到 1.0）
})
