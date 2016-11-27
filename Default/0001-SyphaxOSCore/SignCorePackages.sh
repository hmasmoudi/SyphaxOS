#!/bin/bash

#Change to Packaging Directory of Core 
cd ~/SyphaxOS-Packages

#Loop over Core Packages and create
for Package in *.pkg.tar.xz; do
   echo -e "\n\Signing >>> ${Package} <<< ...\n"

   gpg --detach-sign ${Package}
done
