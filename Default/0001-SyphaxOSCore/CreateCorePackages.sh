#!/bin/bash
cd ~/SyphaxOS-Packing-Scripts/SyphaxOS/Default/0001-SyphaxOSCore/001_BuildPackagesScripts/

for Package in *-*; do
   echo -e "\n\nBuilding >>> ${Package} <<< ...\n"
   pushd ${Package}
   makepkg -cf
   popd
done
