#!/usr/bin/bash

distro=debian
rep=apt
stable="$distro-hwac"
browser=firefox-esr
dependencies=true
stable_pcgs="https://github.com/moio9/proot-hwac/releases/latest"


function alias_proot {
  path=/data/data/com.termux/files/usr/bin
  echo 'Proot Desktop alias is hwac'
  echo '#!/usr/bin/bash'>"$path/hwac"
  echo "path="$path>>"$path/hwac"
  echo "pulseaudio --start --exit-idle-time=-1 &">>"$path/hwac"
  echo "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 &">>"$path/hwac"
  echo "am start -n com.termux.x11/com.termux.x11.MainActivity">>"$path/hwac"
  echo 'proot-distro login debian-hwac --shared-tmp -- bash termux11 $1'>>"$path/hwac"

  chmod +x /data/data/com.termux/files/usr/bin/hwac
}
  
emu_set(){
  mkdir packages
  cd packages
  wget --no-parent -r -l1 -A.deb $stable_pcgs
  dpkg -i *.deb

}

while getopts b:a:t: opts; do
  case $opts} in
    b) proot_official=true ;;
    a) create_alias=false ;;
    t) desktop_termux=true ;;
  esac
done

apt update
apt upgrade
apt install pulseaudio
apt install $browser
apt install glmark2
apt install $session
apt install lutris

alias_proot

if [ "$dependencies" = true ]
  then
    emu_set
fi
