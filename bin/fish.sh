# 插件管理
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

fisher install jorgebucaran/fisher
fisher install jethrokuan/z
fisher install ilancosman/tide@v6

tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Few icons' --transient=No
