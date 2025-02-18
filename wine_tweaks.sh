#!/data/data/com.termux/files/usr/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PREFIX_PATH1=$HOME/.wine
PREFIX_PATH2=/data/data/com.termux/files/usr/glibc/wine

if [ $1 == "hangover" ]; then
    hangover-wine regedit $SCRIPT_DIR/tools/pre_fix.reg
    echo "Prefix $PREFIX_PATH1 creat și configurat!"
fi

if [ $1 != "hangover ]; then
    bine regedit $SCRIPT_DIR/tools/pre_fix.reg
    echo "Prefix $PREFIX_PATH2 creat și configurat!"
fi
