echo  -e "\n======================================"

echo  -en  "[-] 基础设置及启动服务 ..."
sudo systemctl enable v2raya.service>/dev/null 2>&1 &&
sudo systemctl start v2raya.service>/dev/null 2>&1 &&
systemctl --user enable --now pipewire pipewire-pulse wireplumber>/dev/null 2>&1 &&
systemctl --user restart pipewire &&
sudo chown -R clay:clay /data /tools /opt>/dev/null 2>&1  && echo -e "成功" || echo -e "失败"

echo  -ne  "[-] 安装nodejs ... "
nvm install v22.16.0>/dev/null 2>&1 &&
npm config set registry https://registry.npmmirror.com>/dev/null 2>&1 &&
npm install -g yarn && echo -e "成功" || echo -e "失败"

echo  -en  "[-] nvim配置 ... "
# 安装vim插件管理 plug
git clone https://github.com/junegunn/vim-plug.git /tmp/vim-plug>/dev/null 2>&1 &&
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/" &&
cp -rf /tmp/vim-plug/plug.vim "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/" &&
nvim --headless -c 'PlugInstall' -c 'qa' >/dev/null 2>&1 &&
nvim --headless -c 'CocInstall -sync coc-json coc-pyright coc-yaml' -c 'qa' >/dev/null 2>&1 &&
rm -rf /tmp/vim-plug/ && echo -e "成功" || echo -e "失败"


echo  -en  "[-] /opt 软链接 ... "
sudo ln -s /opt/google/chrome/google-chrome /usr/bin/google-chrome &&
sudo ln -s /opt/visual-studio-code/bin/code /usr/bin/code &&
sudo ln -s /opt/discord/Discord /usr/bin/discord &&
sudo ln -s /opt/folo-appimage/folo-appimage.AppImage /usr/bin/folo &&
sudo ln -s /opt/Telegram/Telegram /usr/bin/telegram &&
sudo ln -s /opt/typora/typora /usr/bin/typora &&
sudo ln -s /opt/wemeet/bin/wemeetapp /usr/bin/wemeet &&
sudo ln -s /opt/Cursor-1.2.2-x86_64.AppImage /usr/bin/cursor &&
sudo ln -s /opt/Obsidian-1.8.10.AppImage /usr/bin/obsidian
&& echo -e "成功" || echo -e "失败"

echo  -en  "[-] .desktop文件 ..."
&& echo -e "成功" || echo -e "失败"
