#!/bin/bash
export DVD_NAME=SyphaxOS-DVD-2.0.0_Beta1-x86_64.iso

rm -rf $DVD_NAME
mkdir -pv SyphaxOS
cp -rf live SyphaxOS/
cp -rf boot SyphaxOS/
/usr/bin/grub-mkrescue -d /usr/lib/grub/i386-pc --product-name=SyphaxOS --product-version=2.0.0-Beta1  -o $DVD_NAME SyphaxOS
