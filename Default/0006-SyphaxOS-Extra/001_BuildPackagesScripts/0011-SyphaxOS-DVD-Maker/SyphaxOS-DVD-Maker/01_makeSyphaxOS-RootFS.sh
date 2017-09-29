#!/bin/sh
export HOME_DIR=/home/hmasmoudi
export SOS_DVD=/SyphaxOS-DVD
export DEST_PKG="$SOS_DVD"/Packages/

rm -rf "$SOS_DVD"/*


mkdir -p "$SOS_DVD"/usr/var/lib/pacman/
mkdir -p "$DEST_PKG"

cp -rf "$HOME_DIR"/SyphaxOS-Packages/core/* 	         "$DEST_PKG"
cp -rf "$HOME_DIR"/SyphaxOS-Packages/graphicslayer/*  "$DEST_PKG"
cp -rf "$HOME_DIR"/SyphaxOS-Packages/desktop/* 	      "$DEST_PKG"
cp -rf "$HOME_DIR"/SyphaxOS-Packages/applications/*   "$DEST_PKG"

pacman -r "$SOS_DVD" -Syu SyphaxOS-Installer --cachedir="$DEST_PKG" --noconfirm

printf "toor\ntoor" | chroot "$SOS_DVD" passwd ; chroot "$SOS_DVD" chsh -s "/bin/bash"
chroot "$SOS_DVD" useradd -m -g users "syphaxos"
printf "toor\ntoor" | chroot "$SOS_DVD" passwd "syphaxos"

cp -rf ./AccountServiceUsers.conf "$SOS_DVD"/var/lib/AccountsService/users/syphaxos
chown root:root "$SOS_DVD"/var/lib/AccountsService/users/syphaxos

