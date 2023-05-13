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
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf
cat >> /etc/pacman.conf << EOF
[lib32]
Include = /etc/pacman.d/mirrorlist
EOF
echo '==> Done doing preperations.'

# Add archlinux repositories
echo '==> Adding Arch Linux repositories...'
cat >> /etc/pacman.conf << EOF
[universe]
Server = https://universe.artixlinux.org/\$arch
EOF
pacman -Sy --noconfirm artix-archlinux-support || error
cat >> /etc/pacman.conf << EOF
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
EOF
echo '==> Finished adding Arch Linux repositories.'

# Add chaotic aur repository
echo '==> Adding chaotic aur repository...' 
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || error
pacman-key --lsign-key FBA220DFC880C036 || error
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || error
cat >> /etc/pacman.conf << EOF
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
echo '==> Finished adding chaotic aur repository.'

# default archlinux mirrors are slow as fuck for me, so replace them
echo '==> Replacing archlinux mirrors with better ones...'
rm /etc/pacman.d/mirrorlist-arch
cat >> /etc/pacman.d/mirrorlist-arch << EOF
Server = https://mirror.aarnet.edu.au/pub/archlinux/\$repo/os/\$arch
Server = https://mirrors.dotsrc.org/archlinux/\$repo/os/\$arch
EOF
echo '==> Done.'

# Install necessary packages
echo '==> Installing packages... (This is gonna take a while)'

pacman -Sy --noconfirm --needed \
	base-devel \
	firefox \
	polybar \
	dunst \
	lxsession \
	lxappearance \
	pavucontrol \
	ttf-jetbrains-mono-nerd \
	ttf-proggyclean-nerd \
	xfce4-settings \
	geany \
	bspwm \
	lightdm \
	lightdm-runit \
	lightdm-gtk-greeter \
	catppuccin-gtk-theme-frappe \
	qt5ct \
	kvantum \
	revolt-desktop-git \
	paru \
	rofi \
	sxhkd \
	hyfetch \
	alacritty \
	thunar \
	papirus-icon-theme \
	thunar-volman \
	thunar-archive-plugin \
	thunar-media-tags-plugin \
	tumbler \
	gvfs \
	gvfs-mtp \
	github-cli \
	android-tools \
	scrcpy \
	ntfs-3g \
	xdg-user-dirs \
	bluez \
	bluez-runit \
	blueman \
	flameshot || error

echo '==> Installed packages.'

# Link dotfiles
echo '==> Copying dotfiles to .config'
mkdir -pv /home/$SUDO_USER/.config
cp -rv * /home/$SUDO_USER/.config/ || error
echo '==> Done.'

# Download stuff
echo '==> Downloading stuff...'
mkdir -pv /home/$SUDO_USER/.fonts || error
curl https://raw.githubusercontent.com/google/material-design-icons/master/font/MaterialIcons-Regular.ttf > /home/$SUDO_USER/.fonts/MaterialIcons-Regular.ttf || error
echo '==> Done.'

# Fix permissions
echo '==> Fixing permissions...'
chown -Rv $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config || error
chown -Rv $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.fonts || error
echo '==> Done.'

# Post configuration
echo '==> Performing post configuration...'
echo "QT_QPA_PLATFORMTHEME='qt5ct'" >> /etc/environment
su - $SUDO_USER -c 'xdg-user-dirs-update'
mkdir -p /home/$SUDO_USER/.local/share/rofi/themes
curl https://raw.githubusercontent.com/catppuccin/rofi/main/basic/.local/share/rofi/themes/catppuccin-frappe.rasi > /home/$SUDO_USER/.local/share/rofi/themes/catppuccin-frappe.rasi
echo '==> Done.'

# Post install shell
echo '==> Now do your post install stuff. Pressing CTRL+D will terminate the terminal and start the display manager.'
echo '==> You are logged in as ${SUDO_USER}. There is no visible prompt, but you can type commands.'
echo '==> Install the following stuff using paru (since you cant use paru with root): picom-jonaburg-git'
su - $SUDO_USER -s /bin/bash

# Enable services
echo '==> Enabling services...'
ln -sv /etc/runit/sv/lightdm /run/runit/service
ln -sv /etc/runit/sv/bluetoothd /run/runit/service

echo '==> Done!!'
exit 0
