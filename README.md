# dotfiles

> 个人日常使用的 **Arch Linux + niri** 桌面配置，以及配套的自动化部署脚本。

从刚装好 Arch 的纯 TTY 终端开始，跑几个脚本就能还原出日常使用的整套桌面环境。

过去用过很多窗口管理器：bspwm、i3、awesome、dwm，用得最久的是 awesomewm，其次是 dwm；后来尝试了 Hyprland，一度以为那就是终点 —— 直到遇见 niri，现在主力已经切到 **niri**（可滚动平铺 Wayland 合成器）。

> Hyprland 很好，但 niri 的"横向无限滚动 + 列式布局"在工作流上更顺手。

仓库里的 `lib/config/` 是按 `~/.config` 一比一组织的，安装脚本会把它原样铺到家目录。

---

## 预览

`preview/` 下是桌面实际效果的截图（GitHub 偶尔抽风不显示图片，可以直接到本地看）。

| 预览图 | 内容 |
|--------|------|
| `preview/dunst.png` | dunst 通知样式 |
| `preview/rofi.png` | rofi 启动器 |
| `preview/grub.png` | GRUB 启动主题 |
| `preview/yazi.png` | yazi 文件管理器 |
| `preview/music.png` | cava / 播放器可视化 |
| `preview/neofetch.png` | 系统信息 |
| `preview/swappy-*.png` | swappy 截图标注示例 |

---

## 目录结构

```text
.
├── bin/                        # 早期 bash 版安装脚本（已被根目录 Python 版取代，保留备用）
│   ├── setup.sh                #   软件包安装（bash 版）
│   ├── fish.sh                 #   fish + fisher 插件 + tide 主题
│   ├── zsh.sh                  #   zsh 配置（历史遗留）
│   ├── grub_setup.sh           #   GRUB 主题安装（bash 版）
│   └── actions.sh              #   系统动作执行（bash 版）
│
├── lib/                        # 所有配置清单与源文件
│   ├── pkgs.conf               # 软件包清单（pkg_installer.py 的数据源，分节 + `#` 注释）
│   ├── actions.conf            # 动作清单（setup.py 的数据源：[主题配置] [服务配置] [Node.js配置]）
│   ├── archinstall.json        # archinstall 自动安装配置
│   ├── iwlwifi-QuZ-a0-hr-b0-77.ucode   # Intel Wi-Fi 固件，装机联网时备用
│   │
│   ├── grub/                   # GRUB 主题源文件 → /boot/grub/themes/simple
│   │   ├── theme.txt           #   主题定义
│   │   ├── moon.jpg / sun.jpg  #   背景图
│   │   ├── selected_item_c.png #   选中项指示器
│   │   └── *.pf2               #   DejaVu / Terminus 点阵字体
│   │
│   ├── typora/                 # Typora 主题：blueTex + 内置字体
│   │
│   ├── etc/                    # 系统级配置，安装时落到 /etc
│   │   ├── environment         #   输入法环境变量（QT / SDL / GLFW / XMODIFIERS）
│   │   ├── pacman.conf         #   pacman 优化配置
│   │   ├── vconsole.conf       #   虚拟控制台
│   │   ├── systemd/logind.conf #   login 行为
│   │   ├── fonts/              #   fonts.conf / local.conf
│   │   └── usr/share/icons/    #   fcitx5 托盘图标等
│   │
│   └── config/                 # 用户级配置，与 ~/.config 一一对应
│       ├── niri/               # ★ 窗口管理器（主力）
│       │   ├── config.kdl      #   入口文件，include 下面 8 个 cfg/*.kdl
│       │   ├── cfg/            #   animation / autostart / keybinds / input
│       │   │                   #   / display / layout / rules / misc
│       │   ├── bg/             #   壁纸库（含 2 个 mp4 动态壁纸）
│       │   └── scripts/        #   辅助脚本（见下表）
│       ├── waybar/             # 状态栏：config + style.css / dracula-*.css
│       ├── alacritty/          # 终端模拟器（含 snazzy 主题、nvim-wrapper.sh）
│       ├── rofi/               # 应用启动器 + powermenu（type-2 风格）
│       ├── dunst/              # 桌面通知
│       ├── nvim/               # Neovim（lazy.nvim + lua/plugins）
│       ├── yazi/               # 文件管理器（含 full-border / smart-enter 插件）
│       ├── fcitx5/             # 中文输入法
│       └── pip/                # pip 源配置
│
├── preview/                    # 桌面预览截图
├── log.py                      # 统一彩色日志模块（其余脚本共用）
├── system_installer.py         # ① Arch 基础系统安装
├── pkg_installer.py            # ② 软件包批量安装
├── setup.py                    # ③ 配置落地 / 服务 / Node 环境
├── grub_setup.py               # ④ GRUB 主题安装
└── README.md
```

### niri 辅助脚本

配置拷到 `~/.config/niri/scripts/` 后由快捷键调用：

| 脚本 | 作用 |
|------|------|
| `set-wallpaper.sh` | awww 随机切换壁纸，分别控制工作区背景与概览背景两套实例 |
| `toggle-waybar.sh` | 显示 / 隐藏 waybar |
| `screenshot.sh` | `grim + slurp + swappy` 区域截屏并标注 |
| `bakup.sh` | 备份当前 `~/.config` 回 dotfiles 仓库（自动识别 git 根目录） |
| `ip.sh` | 复制本机 IP（或 C 段）到剪贴板 |
| `fzfmenu.sh` | fzf 模糊启动菜单 |
| `service.sh` | 基于 PID 文件管理服务起停并发送通知 |
| `cpu.sh` / `memory.sh` | waybar 数据脚本：占用 Top 10 进程 |
| `clock.sh` | tty-clock 日历 |
| `start-vmware.sh` | 拉起 vmware 及依赖服务 |
| `reload.sh` | 重载配置（**遗留**：仍调用 `hyprctl`，待改为 `niri msg reload`） |
| `starthypr.sh` | 带环境变量的会话启动脚本（**遗留**：Hyprland 时代的命名） |

---

## Usage

### 完整安装（推荐）

```bash
git clone git@github.com:honkerc/dotfiles.git
cd dotfiles
```

按顺序执行四步：

```bash
# ① 基础系统安装（全新装机时使用，会清空磁盘！）
#    需要 root
sudo python system_installer.py

# ② 安装软件包（读 lib/pkgs.conf，走 paru）
python pkg_installer.py

# ③ 落地配置 + 启用服务 + Node 环境（读 lib/actions.conf）
python setup.py

# ④ GRUB 主题
#    需要 root
sudo python grub_setup.py
```

> **注意**：② 不能用 root 跑（`paru` / `yay` 拒绝以 root 执行 AUR 助手）。
> 已安装过的包会被自动检测并 `SKIP`，中途 Ctrl+C 安全退出。

### 调试模式

`system_installer.py` 和 `grub_setup.py` 支持分步执行某一环节：

```bash
sudo python system_installer.py debug     # 1 网络 / 2 分区 / 3 格式化 / 4 挂载 / 5 镜像源 / 6 基础包
sudo python grub_setup.py debug           # 1 检查主题 / 2 建目录 / 3 拷文件 / 4 备份 / 5 改配置
```

### 全局重载配置

改完 niri 配置后，直接通知 compositor 重载即可（快捷键 `Mod+Shift+/` 可呼出快捷键总览）：

```bash
niri msg reload
```

### 备份当前配置回仓库

桌面里按 `Mod+Shift+U`（即 `bakup.sh`），或手动：

```bash
bash ~/.config/niri/scripts/bakup.sh
```

---

## 各脚本都做了什么

**① `system_installer.py` — 基础系统安装（需 root）**

交互式询问磁盘 / 主机名 / 用户名，输入 `YES` 确认后执行：NTP 对时 → GPT 分区 → 格式化 → 挂载 → 换国内镜像源 → `pacstrap` 基础包 → 生成 fstab → chroot 内配置时区、locale、主机名、用户、sudo、GRUB、NetworkManager。

默认参数集中在 `InstallConfig` 里，改它就行：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `install_disk` | `/dev/nvme0n1` | 目标磁盘 |
| `efi_size` | `+2048M` | EFI 分区 |
| `root_size` / `home_size` / `swap_size` | `+100G` ×3 | 根 / home / swap |
| `hostname` | `archlinux` | 主机名 |
| `username` | `clay` | 用户名 |
| `timezone` | `Asia/Shanghai` | 时区 |
| `locale` | `en_US.UTF-8` | 语言 |
| `base_packages` | base / base-devel / **linux-lts** / linux-firmware / git / neovim / networkmanager / grub / efibootmgr / intel-ucode | 基础包 |

镜像源写死为 USTC / TUNA / BFSU，全程日志落在 `/var/log/arch-install.log`。

**② `pkg_installer.py` — 软件包安装**

解析 `lib/pkgs.conf`，按分节安装。只用 `paru`；单包超时 200 秒；已安装的自动跳过并标记 `SKIP`。

涵盖：系统基础（git / paru / fish）→ 开发工具 → 输入设备驱动 → 蓝牙 → PipeWire 音频 → **niri 核心**（niri、waybar、alacritty、rofi、dunst、swaylock-effects、awww、polkit-gnome）→ XDG Portal → 系统工具 → 截图工具链（grim / slurp / swappy / wl-clipboard）→ fcitx5 输入法 → 字体 → AUR 包（zen-browser、clash-verge-rev、telegram 等）。

NVIDIA 驱动那段默认注释掉了，独显机器自行解开 `[Graphics Drivers]` 节。

**③ `setup.py` — 配置落地与系统调优**

解析 `lib/actions.conf` 并逐条执行 shell 命令（支持 `$HOME` / `~` 展开）。三个小节：

- `[主题配置]`：备份旧 `~/.config` → 铺入新配置 → 安装 fish 插件管理器 fisher 及 `z`、`tide` 主题 → 安装 Typora 主题 → 拷贝 `etc/` 下的系统配置
- `[服务配置]`：启用 v2raya、PipeWire 用户级服务、修正 `/data` `/tools` `/opt` 属主
- `[Node.js配置]`：nvm 装 Node v22.16.0、切 npmmirror 源、装 yarn

fisher 插件清单与 `[主题配置]` 等价的独立版本在 `bin/fish.sh`，需要单独跑 fish 配置时用。

**④ `grub_setup.py` — GRUB 主题（需 root）**

把 `lib/grub/` 复制到 `/boot/grub/themes/simple/`，备份 `/etc/default/grub` 为 `.bak`，写入 `GRUB_THEME`，再依次尝试 `update-grub` → `grub-mkconfig` → `grub2-mkconfig`。重启生效。

---

## Keymap（快捷键）

> `Mod` = TTY 下为 `Super`，在嵌套的 winit 窗口里为 `Alt`。
> 改键看 `lib/config/niri/cfg/keybinds.kdl`，查键名用 `wev`，桌面里 `Mod+Shift+/` 可直接呼出总览。

### 系统与启动

| 快捷键 | 功能 |
|--------|------|
| `Mod + Return` | 打开终端 (Alacritty) |
| `Mod + D` | 应用启动器 (rofi) |
| `Mod + C` | 浏览器 (zen-browser) |
| `Mod + E` | 编辑器 (Obsidian) |
| `Mod + A` | fzf 菜单（新终端内） |
| `Mod + Shift + D` | 锁屏 (swaylock) |
| `Mod + Shift + B` | 切换 waybar 显示 |
| `Mod + Shift + U` | 备份 config 到 dotfiles |
| `Mod + B` | 切换壁纸 |
| `Ctrl + Alt + A` | 区域截图 + swappy 标注 |
| `Mod + Shift + /` | 显示快捷键总览 |
| `Mod + Escape` | 切换快捷键抑制 |
| `Mod + Shift + Q` | 退出 niri |
| `Ctrl + Alt + Delete` | 退出 niri |
| `Mod + Shift + P` | 关闭显示器 |
| `Mod + Alt + S` | 切换屏幕阅读器 (orca) |

### 窗口与列操作

| 快捷键 | 功能 |
|--------|------|
| `Mod + Space` | 切换概览（Overview） |
| `Mod + Q` | 关闭窗口 |
| `Mod + V` | 切换浮动 / 平铺 |
| `Mod + Shift + V` | 在浮动与平铺间切焦 |
| `Mod + W` | 切换列标签模式 |
| `Mod + F` | 最大化当前列 |
| `Mod + Shift + F` | 全屏窗口 |
| `Mod + Ctrl + F` | 填充剩余宽度 |
| `Mod + Ctrl + C` | 居中可见列 |
| `Mod + BracketLeft` / `BracketRight` | 吸入 / 排出左（右）列 |
| `Mod + Comma` | 吸入窗口到当前列 |
| `Mod + Period` | 排出窗口到右侧 |

### 焦点移动

| 快捷键 | 功能 |
|--------|------|
| `Mod + H` / `J` / `K` / `L` | 焦点 左 / 下 / 上 / 右 |
| `Mod + Tab` / `Shift + Tab` | 下一列 / 上一列 |
| `Mod + Home` / `End` | 首列 / 末列 |
| `Mod + Ctrl + H` / `L` | 列左移 / 右移 |
| `Mod + Ctrl + J` / `K` | 窗口下移 / 上移 |
| `Mod + Ctrl + Home` / `End` | 列移到首 / 末位 |
| `Mod + Shift + H` / `J` / `K` / `L` | 焦点移到 左 / 下 / 上 / 右 显示器 |
| `Mod + Shift + Ctrl + H` / `J` / `K` / `L` | 列移到 左 / 下 / 上 / 右 显示器 |

### 工作区

| 快捷键 | 功能 |
|--------|------|
| `Mod + U` / `I` | 下一 / 上一工作区（垂直方向） |
| `Mod + 1` ~ `5` | 直跳工作区 1 ~ 5 |
| `Mod + Shift + 1` ~ `5` | 把当前列送到工作区 1 ~ 5 |
| `Mod + Ctrl + U` / `I` | 列移到下 / 上工作区 |
| `Mod + Shift + I` | 工作区上移 |
| `Mod + 滚轮上/下` | 上 / 下工作区 |
| `Mod + Ctrl + 滚轮上/下` | 列移到上 / 下工作区 |
| `Mod + 滚轮左/右` | 焦点左 / 右列 |
| `Mod + Ctrl + 滚轮左/右` | 列左移 / 右移 |

### 尺寸调整

| 快捷键 | 功能 |
|--------|------|
| `Mod + R` | 循环列宽预设 |
| `Mod + Shift + R` | 循环窗口高度预设 |
| `Mod + Ctrl + R` | 重置窗口高度 |
| `Mod + -` / `=` | 列宽 −10% / +10% |
| `Mod + Shift + -` / `=` | 窗口高度 −10% / +10% |

### 截图

| 快捷键 | 功能 |
|--------|------|
| `Print` | 区域截图 |
| `Ctrl + Print` | 整屏截图 |
| `Alt + Print` | 当前窗口截图 |

### 媒体与硬件键（锁屏时同样可用）

| 快捷键 | 功能 |
|--------|------|
| `XF86AudioRaiseVolume` / `LowerVolume` | 音量 ±（wpctl） |
| `XF86AudioMute` | 静音切换 |
| `XF86AudioMicMute` | 麦克风静音 |
| `XF86MonBrightnessUp` / `Down` | 亮度 ±10%（brightnessctl） |

---

## 已知待办 / 小坑

迁移到 niri 之后仓库里还留了点 Hyprland 时代的痕迹，顺手记一下：

- `lib/actions.conf` 里配置落地那行写的是 `cp -fr lib/.config/* $HOME/.config/`，而实际目录是 `lib/config`（不带点）。**跑 `setup.py` 前需要把这行改成 `lib/config`**，否则配置铺不进去。
- `setup.py` 解析无 `#` 注释的命令时会把命令置空，因此 `actions.conf` 里**每行都必须带 `#` 注释**，否则该行会被跳过。
- `reload.sh` 还在调 `hyprctl`，应改为 `niri msg reload`；`starthypr.sh` 是 Hyprland 时代的命名。
- `set-wallpaper.sh` 里的壁纸目录写死为 `/data/bg`，换机器需要改成自己的壁纸路径（仓库内的样例壁纸在 `lib/config/niri/bg/`）。
- `bin/*.sh` 是 Python 版之前的 bash 实现，功能重复，仅作备用。

---

## License

个人配置文件，随便抄。转载引用随意，别问为什么这么配。
