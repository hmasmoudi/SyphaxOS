#!/bin/bash

#Use 4 CPU cores for building
export MAKEFLAGS='-j 4'

#Change to Packaging Directory of Core 
cd ~/SyphaxOS-Packing-Scripts/SyphaxOS/Default/0001-SyphaxOSCore/001_BuildPackagesScripts/

#Loop over Core Packages and create
for Package in *-*; do
   echo -e "\n\nBuilding >>> ${Package} <<< ...\n"
   pushd ${Package}
   makepkg -cf
   popd
done
