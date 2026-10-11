-- =============================================================================
-- 快捷键配置（对应原 keybinds.conf）
-- hl.bind(按键组合, 动作, [选项表])
--
-- 按键组合格式: "MOD + MOD + KEY"
--   修饰键: SUPER(Win键) | SHIFT | CTRL | ALT
--   示例: "SUPER + SHIFT + Q"
--
-- 常用动作:
--   hl.dsp.exec_cmd("命令")   — 执行 shell 命令
--   hl.dsp.window.close()     — 关闭当前窗口
--   hl.dsp.window.float(...)  — 切换浮动模式
--   hl.dsp.window.fullscreen()— 切换全屏
--   hl.dsp.window.move(...)   — 移动窗口到工作区
--   hl.dsp.window.resize(...) — 调整窗口大小
--   hl.dsp.focus(...)         — 移动焦点 / 切换工作区
--   hl.dsp.workspace.toggle_special(名称) — 切换特殊工作区
--   hl.dsp.exit()             — 退出 Hyprland
--
-- 选项表常用字段:
--   repeating = true  — 长按持续触发（原 binde 的 'e'）
--   locked    = true  — 锁屏时也有效（原 bindl 的 'l'）
--   mouse     = true  — 鼠标按键绑定（原 bindm）
-- =============================================================================

local HOME    = os.getenv("HOME")
local mainMod = "SUPER"  -- 主修饰键（Win 键 / Super 键）

-- ─── 常用程序路径 ────────────────────────────────────────────────────────────
local terminal     = "alacritty"                                  -- 默认终端
local rootTerminal = terminal .. " -e pkexec"                     -- Root 权限终端
local fileManager  = HOME .. "/.config/hypr/scripts/yazi-launcher.sh" -- 文件管理器（yazi）
local browser      = "/usr/bin/zen"           -- 浏览器
local code         = "cursor"               -- VS Code
local htop         = terminal .. " -e btop"                       -- 系统监视器
local menu         = HOME .. "/.config/rofi/launchers/misc/launcher.sh"  -- 启动器
local scriptMenu   = "alacritty -e " .. HOME .. "/.config/self/script/fzfmenu.sh" -- 脚本菜单
local editor       = "/usr/bin/obsidian"                                     -- Markdown 编辑器
-- local power        = HOME .. "/.config/rofi/powermenu/powermenu.sh"  -- 电源菜单
local lock         = "/usr/bin/swaylock"  -- 电源菜单

-- ─── 系统操作命令 ────────────────────────────────────────────────────────────
local suspend  = "systemctl suspend"  -- 挂起
local shutdown = "shutdown now"       -- 关机
local reboot   = "reboot"            -- 重启


-- =============================================================================
-- 基础操作
-- =============================================================================

-- 打开终端
hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd(terminal))
-- 打开 Root 终端（使用 pkexec）
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(rootTerminal))

-- 关闭当前窗口
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- 切换窗口浮动模式
hl.bind(mainMod .. " + Space", hl.dsp.window.float({ action = "toggle" }))

-- 切换全屏
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())


-- =============================================================================
-- 应用启动
-- =============================================================================

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))            -- 启动器（Rofi）
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(scriptMenu))      -- fzf 脚本菜单
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(browser))         -- 浏览器（Chrome）
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(code))            -- VS Code
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(fileManager))     -- 文件管理器（yazi）
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("Telegram"))      -- Telegram
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(editor))          -- Typora 编辑器

-- Cursor IDE（大写 V 与 VS Code 冲突，注意二者都会触发 SUPER+SHIFT+V）
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("/opt/Cursor-1.2.2-x86_64.AppImage"))


-- =============================================================================
-- 工具与脚本
-- =============================================================================

-- 切换窗口布局（scrolling / dwindle / master 循环）
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/change_layout.sh"))

-- 显示 IP 地址信息
hl.bind(mainMod .. " + i", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/ip.sh"))

-- 拾色器（颜色复制到剪切板）
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("sh -c 'hyprpicker | wl-copy'"))

-- 切换 Waybar（显示/隐藏状态栏）
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/toggle-waybar.sh"))

-- 截屏（区域截图）
hl.bind("CTRL + ALT + A", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/screenshot.sh"))


-- =============================================================================
-- SHIFT 组合：较安全的操作
-- =============================================================================

-- 切换壁纸（随机切换图片壁纸）
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/bg.sh"))

-- 退出 Hyprland（回到登录管理器）
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- 电源菜单（锁屏、注销等）
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(lock))

-- 同步 dotfiles
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/update_dotfiles.sh"))

-- 重载配置
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/reload.sh"))

-- 系统监视器（bpytop）
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("alacritty -e bpytop"))

-- 切换 v2raya 代理
hl.bind(mainMod .. " + SHIFT + v", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/toggle-v2raya.sh"))


-- =============================================================================
-- CTRL + SHIFT 组合：高风险操作（需双手操作防止误触）
-- =============================================================================

-- 切换视频壁纸（mp4 动态壁纸）
hl.bind(mainMod .. " + CTRL + SHIFT + B", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/bg_mp4.sh"))

-- 关机（需三键同时按下）
hl.bind(mainMod .. " + CTRL + SHIFT + S", hl.dsp.exec_cmd(shutdown))

-- 重启（需三键同时按下）
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd(reboot))


-- =============================================================================
-- 特殊工作区（Scratchpad / Magic）
-- =============================================================================

-- 显示/隐藏特殊工作区 "magic"（类似 scratchpad）
hl.bind(mainMod .. " + S",       hl.dsp.workspace.toggle_special("magic"))

-- 将当前窗口移入特殊工作区 "magic"
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))


-- =============================================================================
-- 亮度控制（笔记本功能键）
-- locked = true  → 锁屏时也能调节
-- repeating = true → 长按连续调节
-- =============================================================================

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +2%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 2%-"), { locked = true, repeating = true })


-- =============================================================================
-- 音量控制
-- =============================================================================

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))         -- 音量 +5%
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))         -- 音量 -5%
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pamixer --default-source -m")) -- 麦克风静音
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"))           -- 主音量切换静音


-- =============================================================================
-- 媒体播放控制
-- =============================================================================

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- 播放/暂停
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- 暂停
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true }) -- 下一首
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true }) -- 上一首


-- =============================================================================
-- 焦点移动（SUPER + 方向键）
-- =============================================================================

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))  -- 焦点向左
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" })) -- 焦点向右
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))    -- 焦点向上
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))  -- 焦点向下


-- =============================================================================
-- 工作区切换（SUPER + 数字键）
-- 移动窗口到工作区（SUPER + SHIFT + 数字键）
-- 使用循环生成 1-10 的绑定
-- =============================================================================

for i = 1, 10 do
    local key = i % 10  -- 10 对应 0 键

    -- 切换到工作区 i
    hl.bind(mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i }))

    -- 将当前窗口移动到工作区 i
    hl.bind(mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i }))
end


-- =============================================================================
-- 工作区滚动（SUPER + 鼠标滚轮）
-- =============================================================================

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- 切换到下一工作区
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" })) -- 切换到上一工作区


-- =============================================================================
-- 鼠标拖拽操作
-- mouse = true → 标记为鼠标按键绑定
-- =============================================================================

-- SUPER + 左键拖拽：移动窗口
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })

-- SUPER + 右键拖拽：调整窗口大小
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- =============================================================================
-- 键盘调整窗口大小（SUPER + SHIFT + 方向键）
-- 每次调整 50 像素
-- =============================================================================

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x =  50, y =   0 })) -- 向右扩大
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y =   0 })) -- 向左缩小
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x =   0, y = -50 })) -- 向上缩小
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x =   0, y =  50 })) -- 向下扩大



-- 切换到下一个窗口 (对应 hyprctl dispatch cyclenext)
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next())

-- 切换到上一个窗口 (对应 hyprctl dispatch cycleprev)
-- 通过设置 { next = false } 参数来实现[reference:2]
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))



hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
