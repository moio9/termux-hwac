#!/data/data/com.termux/files/usr/bin/bash

version=2.6.1-1
sp=$(pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


if [ "$1" == "--default" ]; then
    export WINEPREFIX=$PREFIX/glibc/.wine
    echo "Using default Wine prefix: $WINEPREFIX"
else
    if [ -z "$WINEPREFIX" ]; then
     	export WINEPREFIX="$HOME/.wine"
        echo "Using custom Wine prefix: $WINEPREFIX"
    fi
fi

if ! command -v gio &> /dev/null; then
    echo "missing gio"
fi


echo "Configuring prefix..."
cd $SCRIPT_DIR
./wine_tweaks.sh hangover

if [ ! -d "dxvk-gplasync-v$version" ]; then
    mkdir -p $PREFIX/glibc/dxvk
    cd $PREFIX/glibc/dxvk
    wget https://gitlab.com/Ph42oN/dxvk-gplasync/-/raw/main/releases/dxvk-gplasync-v$version.tar.gz

    if [ ! -f "dxvk-gplasync-v$version.tar.gz" ]; then
        echo "File exist, exiting..."
        exit 1
    fi

    tar -xvf dxvk-gplasync-v$version.tar.gz || { echo "Extraction failed."; exit 1; }
    cd dxvk-gplasync-v$version
else
    cd dxvk-gplasync-v$version
fi


cp x64/*.dll $WINEPREFIX/drive_c/windows/system32 || echo "Failed x64."
cp x32/*.dll $WINEPREFIX/drive_c/windows/syswow64 || echo "Failed x32."

USER_REG="$WINEPREFIX/user.reg"


if [ -f "$USER_REG" ]; then
    echo "Adding overrides for DXVK în $USER_REG..."
    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "d3d9"="native,builtin"' "$USER_REG"
    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "d3d10"="native,builtin"' "$USER_REG"
    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "d3d10_1"="native,builtin"' "$USER_REG"
    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "d3d11"="native,builtin"' "$USER_REG"
    sed -i '/\[Software\\\\Wine\\\\DllOverrides\]/a "dxgi"="native,builtin"' "$USER_REG"
else
    echo "File $USER_REG doesn't exist. Wine is not configured."
    exit 1
fi

cd ..
gio trash dxvk-gplasync-v$version.tar.gz


cd $sp
if [ -f "./support.sh" ]; then
    ./support.sh
else
    echo ":("
    exit 1
fi
