#!/usr/bin/env bash

## Author  : Aditya Shakya
## Mail    : adi1090x@gmail.com
## Github  : @adi1090x
## Twitter : @adi1090x

# Available Styles
# >> Created and tested on : rofi 1.6.0-1
#
# column_circle     column_square     column_rounded     column_alt
# card_circle     card_square     card_rounded     card_alt
# dock_circle     dock_square     dock_rounded     dock_alt
# drop_circle     drop_square     drop_rounded     drop_alt
# full_circle     full_square     full_rounded     full_alt
# row_circle      row_square      row_rounded      row_alt

theme="full_circle"
dir="$HOME/.config/rofi/powermenu"

# random colors
styles=($(ls -p --hide="colors.rasi" $dir/styles))
color="${styles[$(( $RANDOM % 8 ))]}"

# comment this line to disable random colors
#sed -i -e "s/@import .*/@import \"$color\"/g" $dir/styles/colors.rasi

# comment these lines to disable random style
#themes=($(ls -p --hide="powermenu.sh" --hide="styles" --hide="confirm.rasi" --hide="message.rasi" $dir))
#theme="${themes[$(( $RANDOM % 24 ))]}"

uptime=$(uptime -p | sed -e 's/up //g')

rofi_command="rofi -x11 -theme $dir/full_rounded"

# Options
shutdown=""
reboot=""
lock=""
suspend="󰙧"
logout=""

# Confirmation
confirm_exit() {
	rofi -dmenu\
		-i\
		-no-fixed-num-lines\
		-p "Are You Sure? : "\
		-theme $dir/confirm.rasi
}

# Message
msg() {
	rofi -theme "$dir/message.rasi" -e "Available Options  -  yes / y / no / n"
}

# Variable passed to rofi
options="$shutdown\n$reboot\n$lock\n$suspend\n$logout"

chosen="$(echo -e "$options" | $rofi_command -p "运行时间: $uptime" -dmenu -selected-row 2)"
case $chosen in
    $shutdown)
        ans=$(confirm_exit &)
        if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
            systemctl poweroff
        elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
            exit 0
        else
            msg
        fi
        ;;
    $reboot)
        ans=$(confirm_exit &)
        if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
            systemctl reboot
        elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
            exit 0
        else
            msg
        fi
        ;;
    $lock)
        # 使用 swaylock 锁屏
        swaylock
        ;;
    $suspend)
        # 暂停音频并挂起
        mpc -q pause 2>/dev/null
        amixer set Master mute 2>/dev/null
        # 多种挂起尝试
        systemctl suspend || loginctl suspend || echo "挂起功能不可用"
        ;;
    $logout)
        ans=$(confirm_exit &)
        if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
            # Hyprland 注销方式
            hyprctl dispatch exit
        elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
            exit 0
        else
            msg
        fi
        ;;
esac
