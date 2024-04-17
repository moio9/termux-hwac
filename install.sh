#!/data/data/com.termux/files/usr/bin/bash

distro=debian
env=xfce4
rep=apt
name="$distro-hwac"

proot=false
proot_official=false
create_alias=true
desktop_termux=true

proot_arg="$HOME/proot-hwac/setup-proot.sh"

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
}

function termux-libs {
  wget https://github.com/moio9/proot-hwac/releases/download/lib/termux-deps.tar.xz
  tar -xvf termux-deps.tar.xz
  cd termux-deps
  mv wine $PREFIX/glibc/wine
  chmod +x box/box64
  chmod +x box/box86
  cp -r turnip/glibc $PREFIX
  cp -r box/glibc $PREFIX
  cd ..
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
    sleep 5 && pulseaudio &

    env DISPLAY=:0
    termux-x11 :0 -xstartup "dbus-launch --exit-with-session '$env-session'"
     
fi
EOF


  chmod +x /data/data/com.termux/files/usr/bin/termux11
}
  

while getopts o:a:t: opts; do
  case $opts} in
    o) proot_official=true ;;
    a) create_alias=false ;;
    t) desktop_termux=true ;;
  esac
done

termux-setup-storage
pkg update 
pkg upgrade -y
pkg install -y tur-repo x11-repo
pkg install -y pulseaudio termux-x11-nightly proot-distro wget
pkg install -y freetype git gnutls libandroid-shmem-static 
    libx11 xorgproto libdrm libpixman libxfixes libjpeg-turbo mesa-demos 
    osmesa pulseaudio termux-x11-nightly vulkan-tools xtrans libxxf86vm
    xorg-xrandr xorg-font-util xorg-util-macros libxfont2 libxkbfile
    libpciaccess xcb-util-renderutil xcb-util-image xcb-util-keysyms
    xcb-util-wm xorg-xkbcomp xkeyboard-config libxdamage libxinerama
    libxshmfence neofetch mousepad
pkg install -y vulkan-tools vulkan-loader-android mesa-zink
pkg install -y mesa-vulkan-icd-freedreno mesa-zink
pkg install -y glibc-repo
pkg install -y glibc-runner
pkg install -y mesa-vulkan-icd-freedreno-glibc mangohud-glibc 
    mesa-zink-glibc libx* box64-glibc
pkg install -y libx*
termux-setup-storage
setup_termux

if [ $desktop_termux = true ] ; then
  pkg install $env
  pkg install firefox
  pkg install glmark2
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

termux-libs
chmod +x bine.sh
chmod +x dxvk_in.sh
chmod +x wine_in.sh
chmod +x "/Desktop/Wine Explorer.desktop"
cp bine.sh $PREFIX/glibc/bin/bine
ln -s $PREFIX/glibc/bin/bine $PREFIX/bin
bine boot
./dxvk_in.sh
launcher

