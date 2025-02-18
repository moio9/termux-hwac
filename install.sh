#!/data/data/com.termux/files/usr/bin/bash

distro=debian
env=xfce4
rep=apt
name="$distro-hwac"

proot=false
proot_official=false
create_alias=true
desktop_termux=true
termux_hangover=true
update=false
winepad_in=true
bootx=true

proot_arg="$HOME/proot-hwac/setup-proot.sh"
dir=$(pwd)

function launcher {
    mkdir '/data/data/com.termux/files/home/Desktop/'
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=Wine Explorer
    Comment=Wine File Manager
    Exec=bine explorer
    Icon=xfwm4-default
    Path=
    Terminal=false
    StartupNotify=false" > '/data/data/com.termux/files/home/Desktop/Wine Explorer.desktop'

    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=Wine Config
    Comment=Wine Config Manager
    Exec=bine winecfg
    Icon=gtk-page-setup
    Path=
    Terminal=false
    StartupNotify=false" > '/data/data/com.termux/files/home/Desktop/Wine Config.desktop'

    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=Hang Explorer
    Comment=Wine Explorer Manager Hangover
    Exec=hangover-hangover explorer
    Icon=gtk-caps-lock-warning
    Path=
    Terminal=false
    StartupNotify=false" > '/data/data/com.termux/files/home/Desktop/Hang Explorer.desktop'

    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=Hang Config
    Comment=Wine Config Manager Hangover
    Exec=hangover-wine winecfg
    Icon=org.xfce.xfwm4-tweaks
    Path=
    Terminal=false
    StartupNotify=false" > '/data/data/com.termux/files/home/Desktop/Hang Config.desktop'

    echo "pkill -9 -f wine
    pkill -9 -f .exe "> '/data/data/com.termux/files/home/Desktop/Wine Killer.sh'
}

function termux-libs {
  wget https://github.com/moio9/termux-hwac/releases/download/lib/termux-deps.tar.xz
  tar -xvf termux-deps.tar.xz
  chmod +x -R termux-deps
  cd termux-deps
  cp -r glibc $PREFIX
  cd ..
}

function winetricks_install {
  set -e  # Exit script if any command fails
  PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

  cd "$(mktemp -d)"

  cat > update_winetricks <<_EOF_SCRIPT
#!/bin/sh
set -e

cd "\$(mktemp -d)"
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion
chmod +x winetricks
mv winetricks "$PREFIX/bin"
mv winetricks.bash-completion "$PREFIX/share/bash-completion/completions/winetricks"
_EOF_SCRIPT

  chmod +x update_winetricks
  mv update_winetricks "$PREFIX/bin/"

  # Execute the script to ensure Winetricks is installed
  "$PREFIX/bin/update_winetricks"
}


function setup_termux {
  echo 'Termux Desktop alias is termux11'
  echo 'Use termux11 k to terminate session'

  cat << EOF > /data/data/com.termux/files/usr/bin/termux11
#!/data/data/com.termux/files/usr/bin/bash

if [ "\$1" != "n" ]
  then
    pkill -f app_proces
    pkill -f pulseaudio*
     
fi

if [ "\$1" != "k" ] 
  then

    am start -n com.termux.x11/com.termux.x11.MainActivity
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    export PULSE_SERVER=127.0.0.1

    env DISPLAY=:0
    export GALLIUM_DRIVER=virpipe
    export MESA_GL_VERSION_OVERRIDE=4.0
    MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
    termux-x11 :0 -xstartup "dbus-launch --exit-with-session '$env-session'"
     
fi
EOF


  chmod +x /data/data/com.termux/files/usr/bin/termux11
}
  

while getopts "o:a:t:u:" opts; do
  case $opts in
    o) proot_official=true ;;
    a) create_alias=false ;;
    t) desktop_termux=true ;;
    u) update=true ;;
    *) echo "Invalid Option: -$OPTARG" ;;
  esac
done

if [ "$update" = true ];
  then
    cd $dir
    ./update.sh
    exit 1 
  fi

termux-setup-storage
pkg update 
pkg upgrade -y
pkg install -y tur-repo x11-repo
pkg install -y pulseaudio termux-x11-nightly proot-distro wget
pkg install -y \
    freetype git gnutls libandroid-shmem-static \
    libx11 xorgproto libdrm libpixman libxfixes libjpeg-turbo \
    mesa-demos osmesa pulseaudio termux-x11-nightly vulkan-tools xtrans \
    libxxf86vm xorg-xrandr xorg-font-util xorg-util-macros libxfont2 \
    libxkbfile libpciaccess xcb-util-renderutil xcb-util-image \
    xcb-util-keysyms xcb-util-wm xorg-xkbcomp xkeyboard-config \
    libxdamage libxinerama libxshmfence neofetch mousepad
pkg install -y vulkan-tools vulkan-loader-android mesa-zink
pkg install -y mesa-vulkan-icd-freedreno mesa-zink
pkg install -y glibc-repo
pkg install -y glibc-runner
pkg install -y mesa-vulkan-icd-freedreno-glibc mangohud-glibc 
    mesa-zink-glibc box64-glibc vulkan-volk-glibc
pkg install -y \
    libxcb-glibc libxcomposite-glibc libxcursor-glibc libxfixes-glibc \
    libxrender-glibc libgcrypt-glibc libgpg-error-glibc libice-glibc \
    libsm-glibc libxau-glibc libxcrypt-glibc libxdmcp-glibc \
    libxext-glibc libxinerama-glibc libxkbfile-glibc libxml2-glibc
pkg install -y pulseaudio-glibc libx*-*glibc*
pkg install -y libgmp-glibc
pkg install -y fex
pkg install -y mesa-zink-dev virglrenderer-mesa-zink* virgl_test_server* freetype gnutls \
    libandroid-shmem-static libx11 xorgproto libdrm libpixman libxfixes \
    libjpeg-turbo mesa-demos osmesa pulseaudio termux-x11-nightly vulkan-tools \
    xtrans libxxf86vm xorg-xrandr xorg-font-util xorg-util-macros libxfont2 \
    libxkbfile libpciaccess xcb-util-renderutil xcb-util-image xcb-util-keysyms \
    xcb-util-wm xorg-xkbcomp xkeyboard-config libxdamage libxinerama libxshmfence
pkg install -y virglrenderer-mesa-zink box64-glibc vulkan-volk-glibc
pip install socket
pip install struct
pip install subprocess
pip install re
pip install threading
termux-setup-storage
setup_termux

if [ $desktop_termux = true ] ; then
  pkg install $env
  pkg install firefox
  pkg install glmark2
fi

if [ $termux_hangover = true ] ; then
  tput setab 8
  echo
  printf "$(tput setaf 2)Install bionic hangover... $(tput setaf 1)(experimental)! :"
  tput setab 0
  tput setaf 3;
  
  pkg in hangover*

  cp hangover $PREFIX/bin
  cd $HOME
  wget https://github.com/alexvorxx/hangover-termux/releases/download/9.22/wine_hangover_9.22_bionic_build_patched.tar.xz
  wget https://github.com/alexvorxx/hangover-termux/releases/download/9.5/box64cpu_hangover9.5.zip
  tar -xvf wine_hangover_9.22_bionic_build_patched.tar.xz
  unzip -o box64cpu_hangover9.5.zip -d wine_hangover/arm64-v8a/lib/wine/aarch64-windows
  gio trash hangover_9.5_bionic_box64upd_termux_5patches.tar.xz
  gio trash box64cpu_hangover9.5.zip

  cd $dir
  hangover-wine boot
  WINEPREFIX=$HOME/.wine ./dxvk_in.sh

  sed -i '/^exec/i \
  if [ -z "$WINEPREFIX" ]; then\
    export WINEPREFIX="$HOME/.wine";\
  fi;\
  if [ ! -d "$WINEPREFIX" ]; then\
    echo "Prefix $WINEPREFIX does not exist, running configuring script...";\
    /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine boot;\
    $TERMUX_HWAC/wine_tweaks.sh hangover;\
    exit;\
  fi' /data/data/com.termux/files/usr/bin/hangover-wine
  
  tput setaf 255;
fi

if [ distro = true ] ; then
    if [ $create_alias = true ] ; then
      proot-distro install --override-alias $name $distro
    else
      name="$distro"
      proot-distro install $distro
    fi
    cd $HOME/proot-hwac
    proot-distro login $name --shared-tmp -- $proot_arg
fi

if [ $winepad_in = true ] ; then
    cd $dir
    ./winepad_in.sh
fi

if [ bootx = true ] ; then
    cd
    mkdir -p ~/.termux
    echo "allow-external-apps=true" > ~/.termux/termux.properties
fi

cd $dir

termux-libs
winetricks_install

cd $dir

chmod +x bine.sh
chmod +x dxvk_in.sh
chmod +x wine_in.sh
cp bine.sh $PREFIX/glibc/bin/bine
ln -s $PREFIX/glibc/bin/bine $PREFIX/bin
bine boot
./wine_tweaks.sh
./dxvk_in.sh
launcher
pkg upgrade

echo "glibc-runner $PREFIX/glibc/share/jdk/bin/java $@" > $PREFIX/bin/gava && chmod +x $PREFIX/bin/gava
echo "export GLIBC=$PREFIX/glibc" >> ~/.bashrc
echo "export GLBIN=$PREFIX/glibc/bin" >> ~/.bashrc
echo "export TERMUX_HWAC=$dir" >> ~/.bashrc
echo "export WINE=hangover-wine" >> ~/.bashrc
echo "alias cblinc='cd $PREFIX/glibc/bin'" >> ~/.bashrc
echo "alias kys='killall -u $(whoami)'" >> ~/.bashrc
echo "alias winepad='python $dir/tools/connect_gamepad.py'" >> ~/.bashrc
source ~/.bashrc
termux-reload-settings
sleep 1

tput setaf 13; ./support.sh tput setaf 0;
tput setaf 7;
echo "Type '$(tput setaf 14)termux11' to enter xfce session."
