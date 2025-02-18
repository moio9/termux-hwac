#!/data/data/com.termux/files/usr/bin/env bash

export WINE_PATH=$PREFIX/glibc/wine
if [ -z "$WINEPREFIX" ]; then
    export WINEPREFIX=$PREFIX/glibc/.wine
fi

export WINEESYNC=1
export WINEESYNC_TERMUX=1

#export WINEDLLOVERRIDES="${WINEDLLOVERRIDES},d3d11,d3d10,dxgi,d3d9=n,b"

export VK_ICD_FILENAMES=$PREFIX/glibc/share/vulkan/icd.d/freedreno_icd.aarch64.json
export DXVK_ASYNC=1
export MESA_VK_WSI_PRESENT_MODE=mailbox

export BOX64_PATH=$PREFIX/glibc/bin
export BOX64_MMAP32=1

export GLIBC_BIN=$PREFIX/glibc/bin
LD_PRELOAD_SAVED=$LD_PRELOAD
unset LD_PRELOAD

if [ ! -d "$WINEPREFIX" ]; then
    echo "Prefix $WINEPREFIX does not exist, running configuring script..."
    $GLIBC_BIN/box64 $WINE_PATH/bin/wine boot
    $TERMUX_HWAC/wine_tweaks.sh bine || true
    exit
fi

$GLIBC_BIN/box64 $WINE_PATH/bin/wine "$@"


export LD_PRELOAD=$LD_PRELOAD_SAVED
