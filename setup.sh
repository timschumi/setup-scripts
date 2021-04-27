#!/bin/bash -e

>&2 echo "--- Disabling sudo password requirement ---"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/15-nopasswd

>&2 echo "--- Updating system ---"
sudo pacman -Syyuu --noconfirm

>&2 echo "--- Enabling sudo password requirement ---"
sudo rm -rf /etc/sudoers.d/15-nopasswd
