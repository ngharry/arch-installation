#!/bin/bash

# Install fonts
echo "Installing fonts..."
cd /tmp; git clone https://github.com/powerline/fonts.git --depth=1 && cd fonts
./install.sh && cd $HOME
echo "Finished."

# Install Oh My ZSH
echo "Installing zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "Finished."

echo "Downloading and configuring packages..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/denysdovhan/spaceship-prompt.git \
"$ZSH_CUSTOM/themes/spaceship-prompt" & \
sudo ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" \
"$ZSH_CUSTOM/themes/spaceship.zsh-theme"
echo "Finished."

HOST=https://raw.githubusercontent.com/ngharry/arch-installation/master/arch-config/

echo "Copying config files..."

# Config deepin-terminal
curl $HOST/config.conf > $HOME/.config/deepin/deepin-terminal/config.conf

# Config vim
curl $HOST/vimrc > $HOME/.vimrc

# Config xinitrc
curl $HOST/xinitrc > $HOME/.xinitrc 

# Config auto startx at login
curl $HOST/zprofile.autostartx > $HOME/.zprofile


# Config zsh
curl $HOST/zsh-config > $HOME/.zshrc


