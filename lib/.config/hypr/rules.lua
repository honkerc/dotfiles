-- =============================================================================
-- 窗口规则配置（对应原 rules.conf）
-- hl.window_rule({ match = { 匹配条件 }, 规则属性 = 值 })
--
-- match 常用字段:
--   class      = "正则"  — 匹配窗口 class（通过 hyprctl clients 查看）
--   title      = "正则"  — 匹配窗口标题
--   float      = true/false — 是否浮动窗口
--   fullscreen = true/false — 是否全屏
--   xwayland   = true/false — 是否为 XWayland 窗口
--   pin        = true/false — 是否已置顶
--
-- 常用规则属性:
--   opacity       = 0.92    — 透明度（0.0 完全透明 ~ 1.0 完全不透明）
--   fullscreen    = true    — 强制全屏
--   float         = true    — 强制浮动
--   border_size   = 2       — 窗口边框宽度（像素）
--   max_size      = "W H"   — 最大尺寸限制（浮动窗口有效）
--   no_focus      = true    — 禁止获取焦点
--   suppress_event = "type" — 禁止处理特定事件（如 "maximize"）
-- =============================================================================


-- =============================================================================
-- 终端窗口透明度
-- =============================================================================

-- Alacritty 终端：90% 不透明（轻微透明使背景隐约可见）
hl.window_rule({
    name    = "alacritty-opacity",
    match   = { class = "Alacritty" },
    opacity = 0.92,
})

-- Kitty 终端：同样的透明度设置
hl.window_rule({
    name    = "kitty-opacity",
    match   = { class = "kitty" },
    opacity = 0.92,
})


-- =============================================================================
-- Rofi 启动器：强制全屏显示
-- =============================================================================

hl.window_rule({
    name       = "rofi-fullscreen",
    match      = { class = "Rofi" },
    fullscreen = true,
})


-- =============================================================================
-- Hyprbars 标题栏规则
-- 平铺模式的终端：隐藏标题栏（保持界面简洁）
-- 浮动模式的终端：显示标题栏（方便拖拽移动）
-- =============================================================================

-- 平铺状态下的 Alacritty / Kitty：隐藏标题栏
hl.window_rule({
    name  = "hyprbars-nobar-tiled-terminals",
    match = { class = "^(Alacritty|kitty)$", float = false },
    ["plugin:hyprbars:nobar"] = true,
})

-- 全屏状态下的 Alacritty / Kitty：也隐藏标题栏
hl.window_rule({
    name  = "hyprbars-nobar-fullscreen-terminals",
    match = { class = "^(Alacritty|kitty)$", fullscreen = true },
    ["plugin:hyprbars:nobar"] = true,
})

-- 浮动状态下的 Alacritty：显示标题栏
hl.window_rule({
    name  = "hyprbars-bar-floating-alacritty",
    match = { class = "^(Alacritty)$", float = true },
    ["plugin:hyprbars:bar"] = true,
})


-- =============================================================================
-- 浮动窗口最大尺寸限制
-- 防止特定应用的浮动窗口铺满整个屏幕
-- =============================================================================

hl.window_rule({
    name     = "floating-max-size",
    match    = {
        float = true,
        -- 匹配以下应用（管道符分隔多个 class）
        class = "kitty|Alacritty|google-chrome|Typora|org.telegram.desktop",
    },
    max_size = "1000 600", -- 最大宽度 1000px，最大高度 600px
})


-- =============================================================================
-- 浮动窗口边框
-- 为浮动窗口加上边框，使其与平铺窗口区分更清晰
-- =============================================================================

hl.window_rule({
    name        = "floating-border",
    match       = { float = true },
    border_size = 2, -- 边框宽度 2px（主配置 border_size=0，此规则单独覆盖）
})


-- =============================================================================
-- XWayland 拖拽修复（防止某些应用在 XWayland 模式下出现拖拽故障）
-- =============================================================================

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true, -- 禁止这类无名 XWayland 弹出层获取焦点
})
