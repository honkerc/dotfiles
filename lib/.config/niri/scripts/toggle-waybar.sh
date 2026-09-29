#!/bin/bash

#!/bin/bash

if pidof waybar > /dev/null; then
    pkill waybar
else
    waybar -c $HOME/.config/niri/waybar/config -s $HOME/.config/niri/waybar/style.css &
fi
