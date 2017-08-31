#!/bin/bash
RELEASE="2.2.0-R20170901"
export DVD_NAME=SyphaxOS-DVD-$RELEASE-x86_64.iso

CMD=`pwd`

#generate initrd file
cd /boot
mkinitramfs `uname -r`
mv initrd.img-`uname -r` $CMD/live/initrd.img

#copy most updated Kernel to live directory
cp -rf vmlinuz-SyphaxOs $CMD/live/vmlinuz

# Go back to working directory
cd "$CMD"

#remove old File 
rm -rf $DVD_NAME

#create new directory
mkdir -pv SyphaxOS

#copy live and boot folder
cp -rf live SyphaxOS/
cp -rf boot SyphaxOS/

#Create Iso file
/usr/bin/grub-mkrescue -d /usr/lib/grub/i386-pc --product-name=SyphaxOS --product-version=$RELEASE -o $DVD_NAME SyphaxOS
