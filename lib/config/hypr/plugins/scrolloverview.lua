
-- =============================================================================
-- ScrollOverview — 工作区预览插件
-- =============================================================================

hl.config({
    plugin = {                           -- 2. ScrollOverview 同样需要 plugin 命名空间
        scrolloverview = {
            scale = 0.5,
            workspace_gap = 30,
            layout = "vertical",
            wallpaper = 0,
            blur = false,
            shadow = {
                enabled = true,
                range = 0,
            },
        },
    },
})

-- =============================================================================
-- ScrollOverview 快捷键：SUPER + P 切换预览
-- =============================================================================

hl.bind("SUPER + p", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)

