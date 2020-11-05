#!/bin/bash

# Ce script doit être exécuté sur un nouveau serveur, avec Ubuntu 20.04 LTS.
# PENSEZ À L'ADAPTER EN FONCTION DE VOS BESOINS

CONFIG="/home/ubuntu/config"

# Nécessaire pour éviter les erreurs de LOCALE par la suite
locale-gen "en_US.UTF-8"
timedatectl set-timezone Europe/Paris

# Préparation de la suite

mkdir -p /var/www
mkdir -p /var/lib/caddy/.local/share/caddy
chown ubuntu:ubuntu /var/www
chown ubuntu:ubuntu /var/lib/caddy/.local/share/caddy

echo "======== Mise à jour initiale ========"
apt update
apt -y upgrade
apt -y dist-upgrade
apt -y install libcap2-bin jq unzip mailutils

echo "======== Installation de Caddy ========"
echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" \
    | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
apt update
apt install caddy

cp -rf $CONFIG/etc/caddy/Caddyfile /etc/caddy/
chown caddy:caddy /etc/caddy/Caddyfile
chmod 444 /etc/caddy/Caddyfile

systemctl start caddy

usermod -a -G caddy ubuntu

echo "======== Création des dossiers nécessaires ========"

su ubuntu -c 'mkdir ~/backup'
mkdir -p /var/log/caddy
chown -R caddy:caddy /var/log/caddy

echo "======== Installation de PHP 7.4 ========"
add-apt-repository -y ppa:ondrej/php
apt update
apt -y install php7.4 php7.4-{bcmath,cli,curl,fpm,gd,imagick,json,mbstring,mysql,xml,xmlrpc,zip} imagemagick

# Fichier de configuration
ln -sf $CONFIG/etc/php/conf.d/*.ini /etc/php/7.4/fpm/conf.d
ln -sf $CONFIG/etc/php/pool.d/*.conf /etc/php/7.4/fpm/pool.d

systemctl restart php7.4-fpm

usermod -a -G www-data ubuntu

echo "======== Installation de MySQL ========"
apt -y install mysql-server

tee -a /etc/mysql/mysql.conf.d/binlog.cnf <<EOF
[mysqld]
disable_log_bin
EOF

systemctl restart mysql

echo "======== Installation de WP-CLI ========"
# Installation et déplacement au bon endroit
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Fichier de configuration
su ubuntu -c 'ln -s ~/config/home/.wp-cli ~/'


echo "======== Configuration du pare-feu ========"
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

echo "======== Configuration du SWAP ========"
# Configuration d'un espace swap (merci Composer…)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab


echo "======== Configuration du compte SFTP ========"

addgroup sftp

adduser --home /var/www/ --shell /usr/sbin/nologin --no-create-home --ingroup www-data guillaume
usermod -a -G sftp,caddy guillaume

tee -a /etc/ssh/sshd_config <<EOF
Match Group sftp
    ChrootDirectory %h
    X11Forwarding no
    ForceCommand internal-sftp
EOF

service ssh restart

echo "======== Configuration de l'IPv6 ========"

ln -sf $CONFIG/etc/netplan/51-cloud-init-ipv6.yaml /etc/netplan/
netplan apply

echo "======== Installation des quelques outils ========"
echo "zsh et oh-my-zsh (Shell 2.0)"
apt-get -y install zsh

su ubuntu -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' 

su ubuntu -c 'ln -sf ~/config/home/.alias ~/.alias'
su ubuntu -c 'ln -sf ~/config/home/.zshrc ~/.zshrc'

chsh -s $(which zsh) ubuntu

# Installation des crons automatiques

## Création des fichiers de log
touch /var/log/mysql/backup.log
chown ubuntu:ubuntu /var/log/mysql/backup.log

### Création du cron
tee -a /etc/cron.d/refurb <<EOF
0 0 * * * ubuntu $CONFIG/tools/db.sh > /var/log/mysql/backup.log 2>&1
EOF



# Nettoyages
apt-get -y autoremove
