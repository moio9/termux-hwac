#!/data/data/com.termux/files/usr/bin/bash

version="9.6"
mod="" #-staging
type="" #-tgk

if [ -d 'wine-$version$mod$type-amd64.tar.xz' ]; then
	cd dxvk-gplasync-v$version
else
	cd $PREFIX/glibc
	mv --backup=t wine wine-old
	wget https://github.com/moio9/termux-glibc-hwac/releases/download/lib/wine-$version$mod$type-amd64.tar.xz
	tar -xvf wine-$version$mod$type-amd64.tar.xz
fi
chmod +x -R wine-$version$mod$type-amd64
mv wine-$version$mod$type-amd64 wine
 
cd ..
gio trash wine-$version$mod$type-amd64.tar.xz

./support.sh
