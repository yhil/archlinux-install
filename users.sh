echo "* Installing yay"

cd ~/ && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm

cd ~/ && git clone https://aur.archlinux.org/package-query.git && cd package-query && makepkg -si

cd ~/ && git clone https://aur.archlinux.org/yaourt.git && cd yaourt && makepkg -si

echo ". /usr/lib/python3.8/site-packages/powerline/bindings/zsh/powerline.zsh" >> ~/.zshrc

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "* Installing console packages"
{
sudo pacman --noconfirm -S zsh-autosuggestions powerline powerline-fonts tmux
} >> /tmp/stdout.log

echo "*Installing vs code insiders"
yay visual-studio-code-insiders

sed "s/ZSH_THEME = "robbyrussell"/ZSH_THEMES="agnoster"/"
sed "s/plugin = ()/plugin = (git zsh-autosuggestions)"
