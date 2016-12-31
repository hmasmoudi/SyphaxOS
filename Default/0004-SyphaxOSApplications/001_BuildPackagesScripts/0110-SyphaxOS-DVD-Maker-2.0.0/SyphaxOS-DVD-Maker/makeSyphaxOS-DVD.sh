#!/bin/bash
rm -rf SyphaxOS-2.0.0-Alpha_x86_64.iso
mkdir -pv SyphaxOS
cp -rf live SyphaxOS/
cp -rf boot SyphaxOS/
/usr/bin/grub-mkrescue -d /usr/lib/grub/i386-pc --product-name=SyphaxOS --product-version=2.0.0-Alpha  -o SyphaxOS_2.0.0_alpha.iso SyphaxOS
