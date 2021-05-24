#!/bin/bash -e

OS_INSTALL_XORG=1
OS_INSTALL_LIGHTDM=1
OS_INSTALL_XFCE=1
OS_INSTALL_NETWORKMANAGER=1
OS_INSTALL_PIPEWIRE=1
OS_INSTALL_PULSEAUDIO=
OS_INSTALL_MICROCODE=""
OS_INSTALL_CUPS=1
OS_INSTALL_LIBVIRT=1
OS_INSTALL_VIRTUALBOX=
OS_INSTALL_VAGRANT=1
OS_INSTALL_PODMAN=1
OS_INSTALL_DOCKER=
OS_INSTALL_OPENSSH=1
OS_INSTALL_GIT=1
OS_INSTALL_GNOME_KEYRING=1
OS_INSTALL_STEAM=1
OS_INSTALL_FCITX=1
OS_ENABLE_MULTILIB=1
OS_LOCALES="de_DE.UTF-8:en_US.UTF-8:ja_JP.UTF-8"
OS_THEME="adapta-gtk-theme:Adapta:Adapta-Nokto-Eta"
OS_ICONS="papirus-icon-theme:Papirus"
OS_FONT="noto-fonts:Noto Sans 10"
OS_FONT_MONO="ttf-dejavu:DejaVu Sans Mono 10"
OS_KEYBOARD_LAYOUT="de-latin1-nodeadkeys"
OS_INSTALL_DOTFILES=1
OS_DISABLE_COMPOSITING=1
OS_ENABLE_LOWLATENCY_AUDIO=1
OS_ENABLE_GLOBAL_MEDIA=1
OS_ENABLE_POON_REPO=1
OS_ENABLE_DKP_REPO=1
OS_DISABLE_AUDIT=1
OS_SYSTEMD_RESOLVED=
OS_ENABLE_SSH_SERVER=1
OS_PROVISION_SSH_KEYS="https://timschumi.me/ssh.keys"

# lightdm requires xorg
OS_INSTALL_XORG+="${OS_INSTALL_LIGHTDM}"

# dotfiles requires git
OS_INSTALL_GIT+="${OS_INSTALL_DOTFILES}"

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

if [ -n "${OS_FONT}" ]; then
IFS=':' read -r _OS_FONT_PACKAGE _OS_FONT_NAME <<< "${OS_FONT}"
fi  # OS_FONT

if [ -n "${OS_FONT_MONO}" ]; then
IFS=':' read -r _OS_FONT_MONO_PACKAGE _OS_FONT_MONO_NAME <<< "${OS_FONT_MONO}"
fi  # OS_FONT_MONO


pacman-install() {
    sudo pacman -S "$@" --noconfirm --needed --noprogressbar --quiet
}


>&2 echo "--- Disabling sudo password requirement ---"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/15-nopasswd


if [ -n "${OS_SYSTEMD_RESOLVED}" ]; then
>&2 echo "--- Set up systemd-resolved ---"

sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl enable systemd-resolved --now
sudo systemctl restart systemd-resolved
fi  # OS_SYSTEMD_RESOLVED


if [ -n "${OS_ENABLE_MULTILIB}" ]; then
>&2 echo "--- Enabling multilib ---"
sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sudo sed -i '/^\[multilib\]/!b;n;cInclude = /etc/pacman.d/mirrorlist' /etc/pacman.conf
fi


if [ -n "${OS_ENABLE_POON_REPO}" ]; then
if ! grep -q "thepoon" /etc/pacman.conf; then
>&2 echo "--- Add ThePooN's repo ---"
sudo pacman-key --recv C0E7D0CDB72FBE95 --keyserver hkp://hkps.pool.sks-keyservers.net
sudo pacman-key --lsign C0E7D0CDB72FBE95
sudo tee -a /etc/pacman.conf << 'EOF' > /dev/null
[thepoon]
Server = https://archrepo.thepoon.fr
Server = https://mirrors.celianvdb.fr/archlinux/thepoon
EOF
fi
fi  # OS_ENABLE_POON_REPO


if [ -n "${OS_ENABLE_DKP_REPO}" ]; then
if ! grep -q "dkp" /etc/pacman.conf; then
>&2 echo "--- Add the DKP repo ---"
sudo pacman-key --recv BC26F752D25B92CE272E0F44F7FD5492264BB9D0 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign BC26F752D25B92CE272E0F44F7FD5492264BB9D0

sudo pacman -U https://pkg.devkitpro.org/devkitpro-keyring.pkg.tar.xz --noconfirm --needed --noprogressbar

sudo tee -a /etc/pacman.conf << 'EOF' > /dev/null
[dkp-libs]
Server = https://pkg.devkitpro.org/packages

[dkp-linux]
Server = https://pkg.devkitpro.org/packages/linux/$arch/
EOF
fi
fi  # OS_ENABLE_DKP_REPO


>&2 echo "--- Updating system ---"
sudo pacman -Syyuu --noconfirm


if [ -n "${OS_LOCALES}" ]; then
>&2 echo "--- Setting up locales ---"
_OS_LOCALES_SPLIT=(${OS_LOCALES//:/ })
_OS_LOCALES_PRIMARY="${_OS_LOCALES_SPLIT[0]}"

for loc in "${_OS_LOCALES_SPLIT}"; do
    if grep -q "^${loc} " /etc/locale.gen; then
        continue
    fi

    sudo sed -i "s/^#${loc} /${loc} /g" /etc/locale.gen
done

sudo locale-gen

sudo localectl set-locale LANG=${_OS_LOCALES_PRIMARY}

if [[ "${OS_LOCALES}" =~ *ja_JP* ]]; then
    pacman-install noto-fonts-cjk
fi  # OS_LOCALES =~ *ja_JP*
fi  # OS_LOCALES


if [ -n "${OS_INSTALL_OPENSSH}" ]; then
>&2 echo "--- Installing openssh ---"
pacman-install openssh

if [ -n "${OS_PROVISION_SSH_KEYS}" ]; then
    mkdir -p "${HOME}/.ssh"
    curl "${OS_PROVISION_SSH_KEYS}" > "${HOME}/.ssh/authorized_keys"
fi

if [ -n "${OS_ENABLE_SSH_SERVER}" ]; then
    sudo systemctl enable sshd --now
fi
fi  # OS_INSTALL_OPENSSH


if [[ "${OS_INSTALL_MICROCODE}" =~ intel|amd ]]; then
>&2 echo "--- Installing ${OS_INSTALL_MICROCODE} microcode ---"
pacman-install "${OS_INSTALL_MICROCODE}-ucode"
_OS_CURRENT_BOOT_CONFIG=$(tr -d '\0\006' < /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f)
_OS_CURRENT_BOOT_FILE="/boot/loader/entries/${_OS_CURRENT_BOOT_CONFIG}"
if ! grep -q "ucode" "${_OS_CURRENT_BOOT_FILE}"; then
    sudo sed -i "/^linux.*/a initrd /${OS_INSTALL_MICROCODE}-ucode.img" "${_OS_CURRENT_BOOT_FILE}"
fi
elif [ -n "${OS_INSTALL_MICROCODE}" ]; then
>&2 echo "error: Unknown selection for OS_INSTALL_MICROCODE: '${OS_INSTALL_MICROCODE}'"
exit 1
fi  # OS_INSTALL_MICROCODE


if [ -n "${OS_INSTALL_XORG}" ]; then
>&2 echo "--- Installing Xorg ---"
pacman-install xorg
fi  # OS_INSTALL_XORG


if [ -n "${OS_INSTALL_PIPEWIRE}" ]; then
>&2 echo "--- Installing PipeWire ---"
pacman-install pipewire pipewire-pulse pipewire-alsa pavucontrol
elif [ -n "${OS_INSTALL_PULSEAUDIO}" ]; then  # OS_INSTALL_PIPEWIRE
>&2 echo "--- Installing Pulseaudio ---"
pacman-install pulseaudio pavucontrol
fi  # OS_INSTALL_PULSEAUDIO


if [ -n "${OS_INSTALL_LIGHTDM}" ]; then
>&2 echo "--- Installing lightdm ---"
pacman-install lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm
fi  # OS_INSTALL_LIGHTDM


if [ -n "${OS_INSTALL_XFCE}" ]; then
>&2 echo "--- Installing XFCE ---"
pacman-install xfce4 xfce4-goodies

# Generate XFCE files
if [ ! -d "$HOME/.config/xfce4" ]; then
bash -c 'sleep 5 && xfce4-session-logout --logout' &
startx /usr/bin/startxfce4

xfconf-query -n -c xfce4-panel -p /plugins/plugin-1 -t string -s "whiskermenu"
xfconf-query -n -c xfce4-panel -p /panels -t int -s 1 -a
xfconf-query -n -c xfce4-panel -p /panels/panel-1/position -t string -s "p=8;x=0;y=0"
xfconf-query -n -c xfce4-panel -p /plugins/plugin-14/appearance -t int -s "0"
xfconf-query -n -c xfce4-panel -p /plugins/plugin-14/items -t string -s "+logout" -a

xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -t bool -s "false"
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-home -t bool -s "false"
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -t bool -s "false"
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -t bool -s "false"

xfconf-query -n -c keyboard-layout -p /Default/XkbDisable -t bool -s "true"
fi  # ! -d ~/.config/xfce4
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
xfconf-query -n -c xsettings -p /Net/ThemeName -t string -s "${_OS_THEME_NAME}"
xfconf-query -n -c xfce4-notifyd -p /theme -t string -s "${_OS_THEME_GROUP}"
fi  # OS_INSTALL_XFCE
fi  # OS_THEME


if [ -n "${OS_ICONS}" ]; then
>&2 echo "--- Installing Icons ---"
pacman-install "${_OS_ICONS_PACKAGE}"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -c xsettings -p /Net/IconThemeName -t string -s "${_OS_ICONS_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_ICONS


if [ -n "${OS_FONT}" ]; then
>&2 echo "--- Installing font ---"
pacman-install "${_OS_FONT_PACKAGE}"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -c xsettings -p /Gtk/FontName -t string -s "${_OS_FONT_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_FONT


if [ -n "${OS_FONT_MONO}" ]; then
>&2 echo "--- Installing monospace font ---"
pacman-install "${_OS_FONT_MONO_PACKAGE}"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -c xsettings -p /Gtk/MonospaceFontName -t string -s "${_OS_FONT_MONO_NAME}"
fi  # OS_INSTALL_XFCE
fi  # OS_FONT_MONO


if [ -n "${OS_INSTALL_GIT}" ]; then
>&2 echo "--- Install git ---"
pacman-install git
fi


if [ -n "${OS_INSTALL_DOTFILES}" ] && [ ! -d "$HOME/.dotfiles" ]; then
>&2 echo "--- Installing dotfiles ---"
git clone https://github.com/timschumi/dotfiles "$HOME/.dotfiles"
~/.dotfiles/setup.sh
fi  # OS_INSTALL_DOTFILES


if [ -n "${OS_DISABLE_COMPOSITING}" ]; then
>&2 echo "--- Disabling Compositing ---"

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -c xfwm4 -p /general/sync_to_vblank -t bool -s "false"
xfconf-query -n -c xfwm4 -p /general/vblank_mode -t string -s "off"
xfconf-query -n -c xfwm4 -p /general/use_compositing -t bool -s "false"
fi  # OS_INSTALL_XFCE
fi  # OS_DISABLE_COMPOSITING


if [ -n "${OS_KEYBOARD_LAYOUT}" ]; then
>&2 echo "--- Setting keyboard layout ---"

sudo localectl set-keymap "${OS_KEYBOARD_LAYOUT}" "${OS_KEYBOARD_LAYOUT}"
fi


if [ -n "${OS_INSTALL_CUPS}" ]; then
>&2 echo "--- Installing CUPS ---"
pacman-install cups cups-pdf cups-pk-helper

sudo systemctl enable cups.service

sudo tee /etc/polkit-1/rules.d/49-allow-passwordless-printer-admin.rules << 'EOF' > /dev/null
polkit.addRule(function(action, subject) {
    if (action.id == "org.opensuse.cupspkhelper.mechanism.all-edit" &&
        subject.isInGroup("wheel")){
        return polkit.Result.YES;
    }
});
EOF
fi


# TODO: PipeWire
if [ -n "${OS_ENABLE_LOWLATENCY_AUDIO}" ]; then
>&2 echo "--- Enabling low-latency audio ---"

sudo usermod -aG audio $USER

sudo tee /etc/security/limits.d/15-audio.conf << 'EOF' > /dev/null
@audio - nice -20
@audio - rtprio 99
EOF

if [ -n "${OS_INSTALL_PULSEAUDIO}" ]; then
sudo mkdir -p /etc/pulse/daemon.conf.d
sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf << 'EOF' > /dev/null
high-priority = yes
nice-level = -15

realtime-scheduling = yes
realtime-priority = 50

resample-method = speex-float-0

default-fragments = 2
default-fragment-size-msec = 2
EOF

sudo sed -i '/load-module module-udev-detect/ s/$/ tsched=0/' /etc/pulse/default.pa
fi  # OS_INSTALL_PULSEAUDIO
fi  # OS_ENABLE_LOWLATENCY_AUDIO


if [ -n "${OS_ENABLE_GLOBAL_MEDIA}" ]; then
>&2 echo "--- Mount disks to /media ---"

sudo tee /etc/udev/rules.d/99-udisks2.rules << 'EOF' > /dev/null
# UDISKS_FILESYSTEM_SHARED
# ==1: mount filesystem to a shared directory (/media/VolumeName)
# ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName)
# See udisks(8)
ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
EOF

sudo tee /etc/tmpfiles.d/media.conf << 'EOF' > /dev/null
D /media 0755 root root 0 -
EOF
fi  # OS_ENABLE_GLOBAL_MEDIA


if [ -n "${OS_INSTALL_LIBVIRT}" ]; then
>&2 echo "--- Setting up libvirt ---"
# iptables-nft replaces iptables
sudo pacman -Rdd iptables --noconfirm --noprogressbar

pacman-install \
    libvirt \
    qemu \
    qemu-arch-extra \
    iptables-nft \
    dnsmasq \
    bridge-utils \
    openbsd-netcat \
    virt-manager \
    edk2-ovmf \

sudo usermod -aG libvirt $USER
sudo systemctl enable libvirtd --now
sudo virsh net-autostart default

sudo sed -i '/^hosts:/ s/files /files libvirt libvirt_guest/' /etc/nsswitch.conf

if [ ! -f "/usr/libexec/qemu-kvm" ]; then
    sudo mkdir -p /usr/libexec
    sudo tee /usr/libexec/qemu-kvm << 'EOF' > /dev/null
#!/bin/bash

qemu-system-x86_64 -enable-kvm "$@"
EOF
    sudo chmod a+x /usr/libexec/qemu-kvm
fi
fi  # OS_INSTALL_LIBVIRT


if [ -n "${OS_INSTALL_VIRTUALBOX}" ]; then
>&2 echo "--- Installing VirtualBox ---"
pacman-install virtualbox virtualbox-host-dkms
fi  # OS_INSTALL_VIRTUALBOX


if [ -n "${OS_INSTALL_VAGRANT}" ]; then
>&2 echo "--- Installing Vagrant ---"
pacman-install vagrant packer

sudo tee /etc/security/limits.d/15-nofile.conf << 'EOF' > /dev/null
* hard nofile 524288
* soft nofile 524288
EOF
fi  # OS_INSTALL_VAGRANT


if [ -n "${OS_INSTALL_PODMAN}" ]; then
>&2 echo "--- Installing podman ---"
pacman-install podman buildah podman-compose

echo "$USER:10000:65535" | sudo tee -a /etc/subuid > /dev/null
echo "$USER:10000:65535" | sudo tee -a /etc/subgid > /dev/null
fi  # OS_INSTALL_PODMAN


if [ -n "${OS_INSTALL_DOCKER}" ]; then
>&2 echo "--- Installing docker ---"
pacman-install docker docker-compose
sudo usermod -aG docker $USER
fi  # OS_INSTALL_DOCKER


if [ -n "${OS_DISABLE_AUDIT}" ]; then
_OS_CURRENT_BOOT_CONFIG=$(tr -d '\0\006' < /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f)
_OS_CURRENT_BOOT_FILE="/boot/loader/entries/${_OS_CURRENT_BOOT_CONFIG}"
if ! grep -q "audit" "${_OS_CURRENT_BOOT_FILE}"; then
    sudo sed -i "/^options.*/ s/$/ audit=0/" "${_OS_CURRENT_BOOT_FILE}"
fi
fi  # OS_DISABLE_AUDIT


if [ -n "${OS_INSTALL_GNOME_KEYRING}" ]; then
>&2 echo "--- Installing gnome-keyring ---"
pacman-install gnome-keyring

if [ -n "${OS_INSTALL_XFCE}" ]; then
xfconf-query -n -c xfce4-session -p /compat/LaunchGNOME -t bool -s "true"
fi  # OS_INSTALL_XFCE
fi  # OS_INSTALL_GNOME_KEYRING


if [ -n "${OS_INSTALL_STEAM}" ]; then
>&2 echo "--- Installing steam ---"
pacman-install steam steam-native-runtime
fi  # OS_INSTALL_STEAM


if [ -n "${OS_INSTALL_FCITX}" ]; then
>&2 echo "--- Installing fcitx ---"
pacman-install fcitx fcitx-im

cat << 'EOF' > "${HOME}/.pam_environment"
GTK_IM_MODULE DEFAULT=fcitx
QT_IM_MODULE  DEFAULT=fcitx
XMODIFIERS    DEFAULT=\@im=fcitx
EOF

if [[ "${OS_LOCALES}" =~ *ja_JP* ]]; then
    pacman-install fcitx-mozc
fi  # OS_LOCALES =~ *ja_JP*
fi  # OS_INSTALL_FCITX


>&2 echo "--- Enabling sudo password requirement ---"
sudo rm -rf /etc/sudoers.d/15-nopasswd
