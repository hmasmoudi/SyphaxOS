#!/bin/bash

#Change to Packaging Directory of Core 
cd ~/SyphaxOS-Packages

#Loop over Core Packages and create
for Package in *.pkg.tar.gz; do
   echo -e "\n\nSigning >>> ${Package} <<< ...\n"

   gpg --detach-sign ${Package}
done
