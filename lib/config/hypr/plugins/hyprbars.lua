-- =============================================================================
-- Hyprbars — 仿 macOS 标题栏插件 (macOS 风格)
-- 官方文档: https://github.com/hyprwm/hyprland-plugins/blob/main/hyprbars/README.md
-- =============================================================================

hl.config({
    plugin = {
        hyprbars = {
            -- ── 标题栏外观 ──────────────────────────────────────────────
            bar_color = "rgb(f5f5f5)",         -- 标题栏背景色：浅灰白，类似 macOS
            ["col.text"] = "rgb(1e1e1e)",      -- 标题文字颜色：深色，保证对比度
            bar_height = 32,                   -- 标题栏高度（像素）
            bar_text_size = 12,                -- 文字大小
            bar_text_weight = "semibold",      -- 文字粗细
            bar_text_font = "SF Pro Display, Helvetica, Sans", -- 字体优先级
            bar_text_align = "center",         -- 标题文字对齐方式
            bar_buttons_alignment = "left",    -- ★ 核心修改：交通灯按钮放在左侧
            bar_padding = 12,                  -- 标题栏左右内边距
            bar_button_padding = 8,            -- 按钮之间的间距

            -- ── 标题栏效果 ──────────────────────────────────────────────
            bar_blur = true,                   -- 标题栏毛玻璃模糊
            bar_part_of_window = false,        -- 标题栏不计入窗口内容区域
            bar_precedence_over_border = true, -- 标题栏层级高于窗口边框
            icon_on_hover = true,              -- 仅在鼠标悬停时显示按钮图标
            
            -- ★ 核心修改：已移除 inactive_button_color，非活动窗口按钮保持原本颜色
            -- inactive_button_color = "rgb(666666)", 

            -- ── 交互行为 ────────────────────────────────────────────────
            on_double_click = "hyprctl dispatch fullscreen 1", -- 双击标题栏全屏
        },
    },
})

-- =============================================================================
-- 交通灯按钮定义 (使用 hl.plugin.hyprbars.add_button 函数)
-- =============================================================================

-- 红色按钮 (关闭窗口)
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(ff5f57)",          -- macOS 关闭按钮红
    fg_color = "rgb(ffffff)",
    size = 14,
    icon = "X",
    action = "hyprctl dispatch 'hl.dsp.window.close()'",
})

-- 黄色按钮 (最大化/全屏)
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(febc2e)",          -- macOS 最小化按钮黄
    fg_color = "rgb(000000)",
    size = 14,
    icon = "_",
    action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
})

-- 绿色按钮 (切换特殊工作区)
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(28c840)",          -- macOS 最大化按钮绿
    fg_color = "rgb(000000)",
    size = 14,
    icon = "",
    action = "hyprctl dispatch togglespecialworkspace",
})
