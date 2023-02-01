#!/bin/bash

set -eu

: "${OS_HOSTNAME:=rpi}"
: "${OS_USERNAME:=rpi}"
: "${OS_INSTALL_DOCKER:=false}"

export DEBIAN_FRONTEND=noninteractive

>&2 echo "--- Update the system ---"
apt update
apt upgrade -y

>&2 echo "--- Install various utilities ---"
apt install -y curl bash-completion debconf-utils vim

>&2 echo "--- Disable applying settings from /boot/firmware/sysconf.txt ---"
systemctl disable rpi-set-sysconf

>&2 echo "--- Set the hostname ---"
hostnamectl set-hostname "${OS_HOSTNAME}"
echo "127.0.0.1 ${OS_HOSTNAME}" >> /etc/hosts

>&2 echo "--- Set up the primary user ---"
useradd -m -s /bin/bash "${OS_USERNAME}"

>&2 echo "--- Set up the SSH server ---"
apt install -y openssh-server curl
mkdir "/home/${OS_USERNAME}/.ssh"
curl "https://timschumi.net/ssh.keys" > "/home/${OS_USERNAME}/.ssh/authorized_keys"
chown -R "${OS_USERNAME}:${OS_USERNAME}" "/home/${OS_USERNAME}/.ssh"

>&2 echo "--- Set up sudo ---"
apt install -y sudo
usermod -aG sudo tim

if [ "${OS_INSTALL_DOCKER}" = "true" ]; then
  >&2 echo "--- Set up docker ---"
  apt install -y docker docker-compose
  usermod -aG docker tim
  systemctl enable docker.service
fi  # OS_INSTALL_DOCKER
