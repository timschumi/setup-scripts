#!/bin/bash -e

OS_INSTALL_LIGHTDM=1
OS_INSTALL_XFCE=1
OS_INSTALL_NETWORKMANAGER=1

_OS_NEEDS_XORG="${OS_INSTALL_LIGHTDM}"

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


>&2 echo "--- Enabling sudo password requirement ---"
sudo rm -rf /etc/sudoers.d/15-nopasswd
