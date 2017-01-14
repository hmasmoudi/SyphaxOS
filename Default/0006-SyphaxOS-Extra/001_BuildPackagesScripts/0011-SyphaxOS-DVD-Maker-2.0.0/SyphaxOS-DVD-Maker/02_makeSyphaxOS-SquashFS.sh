#!/bin/bash

CMD=`pwd`

rm -rf SyphaxOS/live/syphaxos.sqsh
mkdir -pv SyphaxOS/live

cd /SyphaxOS-2.0.0-DVD

mksquashfs dev proc run sys bin boot etc home lib lib64 media mnt opt root sbin srv usr var tmp Packages "$CMD"/SyphaxOS/live/syphaxos.sqsh
