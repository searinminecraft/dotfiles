#!/bin/bash

exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log" >&2)

if [ "$EUID" -ne 0 ];then
    echo "Please run this script as root user"
    exit 1
fi

error() {
	echo -e 'Something went wrong. Quitting.'
	exit 1
}

# Do some stuff
echo '==> Doing preperations...'
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g'
cat >> /etc/pacman.conf << EOF
[lib32]
Include = /etc/pacman.d/mirrorlist
EOF

# Add archlinux repositories
echo '==> Adding Arch Linux repositories...'
cat >> /etc/pacman.conf << EOF
[universe]
Server = https://universe.artixlinux.org/\$arch
EOF
pacman -S --noconfirm artix-archlinux-support || error
cat >> /etc/pacman.conf << EOF
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
EOF

# Add chaotic aur repository
echo '==> Adding chaotic aur repository...' 
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || error
pacman-key --lsign-key FBA220DFC880C036 || error
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || error
cat >> /etc/pacman.conf << EOF
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

# Install necessary packages
echo '==> Installing packages... (This is gonna take a while)'
pacman -S --noconfirm --needed base-devel firefox polybar dunst lxsession lxappearance pavucontrol ttf-jetbrainsmono-nerdy ttf-proggyclean-nerd xfce4-settings geany bspwm lightdm lightdm-runit lightdm-gtk-greeter catppuccin-gtk-theme-frappe qt5ct kvantum revolt-desktop-git paru rofi || error

# Install AUR packages
echo '==> Installing AUR packages...'
paru -S --noconfirm picom-jonaburg-git vencord-desktop-git || error

# Link dotfiles
echo '==> Symlinking dotfiles to .config'
ln -s * $HOME/.config/ || error

# Download stuff
echo '==> Downloading stuff...'
mkdir -p /home/$SUDO_USER/.fonts || error
curl https://raw.githubusercontent.com/google/material-design-icons/master/font/MaterialIcons-Regular.ttf > /home/$SUDO_USER/.fonts/MaterialIcons-Regular.ttf || error

# Fix permissions
echo '==> Fixing permissions...'
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config || error
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.fonts || error

# Enable services
echo '==> Enabling services...'
ln -s /etc/runit/sv/lightdm /run/runit/service

echo '==> Done!!'
exit 0
