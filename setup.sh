#!/bin/bash -e

OS_INSTALL_LIGHTDM=1
OS_INSTALL_XFCE=1
OS_INSTALL_NETWORKMANAGER=1
OS_THEME="adapta-gtk-theme:Adapta:Adapta-Nokto-Eta"
OS_ICONS="papirus-icon-theme:Papirus"
OS_INSTALL_DOTFILES=1
OS_DISABLE_COMPOSITING=1

_OS_NEEDS_XORG="${OS_INSTALL_LIGHTDM}"

if [ -n "${OS_THEME}" ]; then
_OS_THEME_SPLIT=(${OS_THEME//:/ })
_OS_THEME_PACKAGE="${_OS_THEME_SPLIT[0]}"
_OS_THEME_GROUP="${_OS_THEME_SPLIT[1]}"
_OS_THEME_NAME="${_OS_THEME_SPLIT[2]}"
fi  # OS_THEME

if [ -n "${OS_ICONS}" ]; then
_OS_ICONS_SPLIT=(${OS_ICONS//:/ })
_OS_ICONS_PACKAGE="${_OS_ICONS_SPLIT[0]}"
_OS_ICONS_NAME="${_OS_ICONS_SPLIT[1]}"
fi  # OS_ICONS

pacman-install() {
    sudo pacman -S "$@" --noconfirm --needed --noprogressbar --quiet
}

>&2 echo "--- Disabling sudo password requirement ---"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/15-nopasswd

>&2 echo "--- Updating system ---"
sudo pacman -Syyuu --noconfirm


if [ -n "${_OS_NEEDS_XORG}" ]; then
>&2 echo "--- Installing Xorg ---"
pacman-install xorg
fi  # _OS_NEEDS_XORG


if [ -n "${OS_INSTALL_LIGHTDM}" ]; then
>&2 echo "--- Installing lightdm ---"
pacman-install lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm
fi  # OS_INSTALL_LIGHTDM


if [ -n "${OS_INSTALL_XFCE}" ]; then
>&2 echo "--- Installing XFCE ---"
pacman-install xfce4 xfce4-goodies
fi  # OS_INSTALL_XFCE


if [ -n "${OS_INSTALL_NETWORKMANAGER}" ]; then
>&2 echo "--- Installing NetworkManager ---"
pacman-install networkmanager network-manager-applet
sudo systemctl enable NetworkManager
fi  # OS_INSTALL_NETWORKMANAGER


if [ -n "${OS_THEME}" ]; then
>&2 echo "--- Installing Theme ---"
pacman-install "${_OS_THEME_PACKAGE}"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -t string -c xsettings -p /Net/ThemeName -s "${_OS_THEME_NAME}"
xfconf-query -n -t string -c xfce4-notifyd -p /theme -s "${_OS_THEME_GROUP}"
fi  # OS_INSTALL_XFCE
fi  # OS_THEME


if [ -n "${OS_ICONS}" ]; then
>&2 echo "--- Installing Icons ---"
pacman-install "${_OS_ICONS_PACKAGE}"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -t string -c xsettings -p /Net/IconThemeName -s "${_OS_ICONS_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_ICONS


if [ -n "${OS_INSTALL_DOTFILES}" ] && [ ! -d "$HOME/.dotfiles" ]; then
>&2 echo "--- Installing dotfiles ---"
git clone https://github.com/timschumi/dotfiles "$HOME/.dotfiles"
~/.dotfiles/setup.sh
fi  # OS_INSTALL_DOTFILES


if [ -n "${OS_DISABLE_COMPOSITING}" ]; then
>&2 echo "--- Disabling Compositing ---"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -t bool -c xfwm4 -p /general/sync_to_vblank -s "false"
xfconf-query -n -t string -c xfwm4 -p /general/vblank_mode -s "off"
xfconf-query -n -t bool -c xfwm4 -p /general/use_compositing -s "false"
fi  # OS_INSTALL_XFCE
fi  # OS_DISABLE_COMPOSITING


>&2 echo "--- Enabling sudo password requirement ---"
sudo rm -rf /etc/sudoers.d/15-nopasswd
