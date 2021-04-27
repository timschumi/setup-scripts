#!/bin/bash -e

OS_INSTALL_LIGHTDM=1
OS_INSTALL_XFCE=1
OS_INSTALL_NETWORKMANAGER=1
OS_THEME="adapta-gtk-theme:Adapta-Nokto-Eta"
OS_ICONS="papirus-icon-theme:Papirus"

_OS_NEEDS_XORG="${OS_INSTALL_LIGHTDM}"

if [ -n "${OS_THEME}" ]; then
_OS_THEME_SPLIT=(${OS_THEME//:/ })
_OS_THEME_PACKAGE="${_OS_THEME_SPLIT[0]}"
_OS_THEME_NAME="${_OS_THEME_SPLIT[1]}"
fi  # OS_THEME

if [ -n "${OS_ICONS}" ]; then
_OS_ICONS_SPLIT=(${OS_ICONS//:/ })
_OS_ICONS_PACKAGE="${_OS_ICONS_SPLIT[0]}"
_OS_ICONS_NAME="${_OS_ICONS_SPLIT[1]}"
fi  # OS_ICONS

>&2 echo "--- Disabling sudo password requirement ---"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/15-nopasswd

>&2 echo "--- Updating system ---"
sudo pacman -Syyuu --noconfirm


if [ -n "${_OS_NEEDS_XORG}" ]; then
>&2 echo "--- Installing Xorg ---"
sudo pacman -S xorg --noconfirm
fi  # _OS_NEEDS_XORG


if [ -n "${OS_INSTALL_LIGHTDM}" ]; then
>&2 echo "--- Installing lightdm ---"
sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm
sudo systemctl enable lightdm
fi  # OS_INSTALL_LIGHTDM


if [ -n "${OS_INSTALL_XFCE}" ]; then
>&2 echo "--- Installing XFCE ---"
sudo pacman -S xfce4 xfce4-goodies --noconfirm
fi  # OS_INSTALL_XFCE


if [ -n "${OS_INSTALL_NETWORKMANAGER}" ]; then
>&2 echo "--- Installing NetworkManager ---"
sudo pacman -S networkmanager network-manager-applet --noconfirm
sudo systemctl enable NetworkManager
fi  # OS_INSTALL_NETWORKMANAGER


if [ -n "${OS_THEME}" ]; then
>&2 echo "--- Installing Theme ---"
sudo pacman -S "${_OS_THEME_PACKAGE}" --noconfirm

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -c xsettings -p /Net/ThemeName -s "${_OS_THEME_NAME}"
xfconf-query -c xfce4-notifyd -p /theme -s "${_OS_THEME_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_THEME


if [ -n "${OS_ICONS}" ]; then
>&2 echo "--- Installing Icons ---"
sudo pacman -S "${_OS_ICONS_PACKAGE}" --noconfirm

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -c xsettings -p /Net/IconThemeName -s "${_OS_ICONS_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_ICONS


>&2 echo "--- Enabling sudo password requirement ---"
sudo rm -rf /etc/sudoers.d/15-nopasswd
