#!/data/data/com.termux/files/usr/bin/bash

version=2.3.1-1

if [ -d 'dxvk-gplasync-v$version' ]; then
	cd dxvk-gplasync-v$version
else
	mkdir $PREFIX/glibc/dxvk
	cd $PREFIX/glibc/dxvk
	wget https://gitlab.com/Ph42oN/dxvk-gplasync/-/raw/main/releases/dxvk-gplasync-v$version.tar.gz
	tar -xvf dxvk-gplasync-v$version.tar.gz
	cd dxvk-gplasync-v$version
fi

if [ -v $WINEPREFIX ]; then
	export WINEPREFIX=$PREFIX/glibc/.wine
fi

bine boot

cp x64/*.dll $WINEPREFIX/drive_c/windows/system32
cp x32/*.dll $WINEPREFIX/drive_c/windows/syswow64
 
cd ..
gio trash dxvk-gplasync-v$version.tar.gz
