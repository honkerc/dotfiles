#!/bin/bash

if ! which git > /dev/null 2>&1; then
    echo -e "\ngit is not found.\nexit with code 1.\n"
    exit 1
elif ! which curl > /dev/null 2>&1; then
    echo -e "\ncurl is not found.\nexit with code 1.\n"
    exit 1
elif ! which zsh > /dev/null 2>&1; then
    echo -e "\nzsh is not found.\nexit with code 1.\n"
    exit 1
fi

curl -k -sSL https://gitee.com/xiaoqqya/ohmyzsh/raw/master/tools/install.sh | sed "s/\$REMOTE/https:\/\/gitee.com\/xiaoqqya\/ohmyzsh.git/g" | sed "/.*exec zsh.*/d" > $HOME/.temp

cat <<EOF >> $HOME/.temp

git clone https://gitee.com/xiaoqqya/spaceship-prompt.git "\$ZSH/custom/themes/spaceship-prompt" --depth=1
ln -s "\$ZSH/custom/themes/spaceship-prompt/spaceship.zsh-theme" "\$ZSH/custom/themes/spaceship.zsh-theme"
echo -e "\n"

git clone https://gitee.com/xiaoqqya/zsh-autosuggestions.git \${ZSH:-~/.oh-my-zsh}/custom/plugins/zsh-autosuggestions
echo -e "\n"

git clone https://gitee.com/xiaoqqya/zsh-syntax-highlighting.git \${ZSH:-~/.oh-my-zsh}/custom/plugins/zsh-syntax-highlighting
echo -e "\n"

git clone https://gitee.com/xiaoqqya/conda-zsh-completion.git \${ZSH:-~/.oh-my-zsh}/custom/plugins/conda-zsh-completion
EOF

sh $HOME/.temp
rm -rf $HOME/.temp

echo  -e "\n======================================"

echo  -ne  "[-] 复制主题配置到.config ..."
rm -fr $HOME/.config>/dev/null 2>&1 &&
cp -fr .config $HOME/.config && echo -e "成功" || echo -e "失败"

echo  -ne  "[-] 配置zsh主题 ..."
cp -fr .config/nicoulaj.zsh-theme $HOME/.oh-my-zsh/themes/ >/dev/null 2>&1 &&
cp -rf .zshrc $HOME/ && echo -e "成功" || echo -e "失败"


exec zsh -l
