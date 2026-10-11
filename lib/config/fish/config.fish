if status is-interactive
    # Commands to run in interactive sessions can go here
    pokemon-colorscripts -r -s --no-title 2>/dev/null; or true
end

# 取消欢迎语句
set -U fish_greeting ""

# 环境变量
set -Ux GIT_CONFIG_GLOBAL "$HOME/.config/git/config"
set -gx BG_PATH /data/bg/img
set -gx DOTFILES /data/dotfiles 

# PATH 设置
fish_add_path $HOME/.config/script/
fish_add_path $HOME/.config/bin/
fish_add_path $HOME/.bin

# 别名设置
if command -q eza
    alias ls='eza --icons'
    alias la='eza -la --icons'
    alias ll='eza -ll --icons'
    alias lt='eza --tree --icons'
else
    alias ls='ls --color=auto'
    alias la='ls -la --color=auto'
    alias ll='ls -l --color=auto'
end

# 设置编辑器命令
# if command -q nvim && test -f "$HOME/.config/self/script/nvim-nopadding.sh"
#     # Fish 使用 command -q 来检查命令是否存在
#     # && 用于逻辑与操作
#     set -gx EDITOR "$HOME/.config/self/script/nvim-nopadding.sh"
# else if command -q nvim
#     set -gx EDITOR "nvim"
# else
#     set -gx EDITOR "vim"
# end
set -gx EDITOR "nvim"
alias nvim="$EDITOR"
alias vim="$EDITOR"
alias nv="$EDITOR"
alias cat='bat -p --paging=never'
alias grep='grep --color=auto'
alias gdd='cd "$HOME/Downloads/"'
alias ddd='cd $DOTFILES'
alias ccc='cd $HOME/.config'

alias gi="git init"
alias gs="git status"
alias syy="sudo pacman -Syy"
alias syu="sudo pacman -Syu"

# alias y="yazi"
alias h="start-hyprland > .hypr.log"
alias n="niri-session  > .niri.log"
alias o="xdg-open"
alias q="sudo pacman -Rns (pacman -Qdtq)"
alias i="curl -s \"http://ip-api.com/json/?fields=country,city,timezone,isp,proxy\" | python3 -m json.tool"
# 重新加载 Fish 配置
function rsf
    source "$HOME/.config/fish/config.fish"
end

# 激活虚拟环境
function active
    bash -c "source $HOME/.venv/bin/activate; exec fish"
end



function open_yazi
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $PWD --cwd-file="$tmp"
    if set -l cwd (cat "$tmp" 2>/dev/null); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd "$cwd"
    end
    rm -f "$tmp"
end

bind \cy open_yazi  # Alt+y
