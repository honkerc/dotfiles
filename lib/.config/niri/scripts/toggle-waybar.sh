#!/bin/bash

#!/bin/bash

if pidof waybar > /dev/null; then
    pkill waybar
else
    waybar -c $HOME/.config/waybar/config -s $HOME/.config/waybar/style.css &
fi
