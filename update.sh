#!/data/data/com.termux/files/usr/bin/bash

set -e  
set -u  

CURRENT_DIR=$(pwd)
cd $CURRENT_DIR
cd ..
if [ "$(basename "$CURRENT_DIR")" != "termux-hwac" ]; then
    echo "Not in 'termux-hwac'."
    cd ..
fi

mv termux-hwac termux-old

echo "Cloning repository..."
if git clone https://github.com/moio9/termux-hwac.git; then
    echo "Repository cloned succesfull."
else
    echo "Eroare at cloning repository."
    exit 1
fi

chmod +x -R termux-hwac

echo "Starting instalation..."
cd termux-hwac
if ./install.sh; then
    echo "Instalation completed succesfull!"
else
    echo "Error at running 'install.sh'."
    exit 1
fi

