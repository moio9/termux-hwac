#!/data/data/com.termux/files/usr/bin/bash

distro=debian
env=xfce4
rep=apt
name="$distro-hwac"

proot_official=false
create_alias=true
desktop_termux=true

proot_arg="$HOME/proot-hwac/setup-proot.sh"

function setup_termux {
  echo 'Termux Desktop alias is termux11'
  echo 'Use termux11 k to terminate session'

  cat << EOF > /data/data/com.termux/files/usr/bin/termux11
#!/data/data/com.termux/files/usr/bin/bash
pkill -f app_proces
pkill -f pulseaudio*

if [ "\$#" -eq 0 ] 
  then
    export PULSE_SERVER=127.0.0.1

    am start -n com.termux.x11/com.termux.x11.MainActivity
    sleep 5 && pulseaudio &

    env DISPLAY=:0
    termux-x11 :0 -xstartup "dbus-launch --exit-with-session '$env-session'"
    
    export PULSE_SERVER=127.0.0.1 && pulseaudio --start --disable-shm=1 --exit-idle-time=-1 
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
pkg upgrade
pkg install pulseaudio
pkg install x11-repo
pkg install termux-x11-nightly
pkg install proot-distro
pkg install wget

setup_termux

if [ $desktop_termux = true ] ; then
  pkg install $env
  pkg install firefox
  pkg install glmark2
fi

if [ $create_alias = true ] ; then
  proot-distro install --override-alias $name $distro
else
  name="$distro"
  proot-distro install $distro
fi

cd $HOME/proot-hwac
proot-distro login $name --shared-tmp -- $proot_arg
