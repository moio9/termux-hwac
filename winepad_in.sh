#!/bin/bash

# Locația de descărcare a pachetului
DOWNLOAD_URL="https://github.com/moio9/termux-hwac/releases/download/dll/lib.tar.xz"
PACKAGE_NAME="lib.tar.xz"

GLIBC_PATH="/data/data/com.termux/files/usr/glibc/wine"
PKG_PATH="/data/data/com.termux/files/usr/opt/hangover-wine"
GITHUB_PATH="/data/data/com.termux/files/home/wine_hangover/arm64-v8a"

# Funcție pentru a verifica dacă un fișier există și să-l descarce dacă nu există
download_if_not_exists() {
    if [ ! -f "$PACKAGE_NAME" ]; then
        echo "Fișierul $PACKAGE_NAME nu a fost găsit. Descărcare..."
        curl -L -o "$PACKAGE_NAME" "$DOWNLOAD_URL"
        if [ $? -ne 0 ]; then
            echo "Eroare la descărcarea fișierului!"
            exit 1
        fi
        echo "Descărcare finalizată."
    else
        echo "Fișierul $PACKAGE_NAME există deja. Se va utiliza acesta."
    fi
}

# Funcție pentru a dezarhiva fișierul .tar.xz
extract_package() {
    if [ -f "$PACKAGE_NAME" ]; then
        echo "Dezarhivare a fișierului $PACKAGE_NAME..."
        tar -xJf "$PACKAGE_NAME"
        if [ $? -ne 0 ]; then
            echo "Eroare la dezarhivarea fișierului!"
            exit 1
        fi
        echo "Dezarhivare finalizată."
    else
        echo "Eroare: Fișierul $PACKAGE_NAME nu există!"
        exit 1
    fi
}

# Funcție pentru a copia conținutul dezarhivat (întregul director lib) în destinațiile predefinite
copy_to_default_destinations() {
    for DEST in "$GLIBC_PATH" "$PKG_PATH" "$GITHUB_PATH"; do
        if [ ! -d "$DEST" ]; then
            echo "Eroare: Directorul $DEST nu există!"
            continue
        fi
        echo "Copiaza întregul director lib in $DEST"
        cp -rf lib "$DEST"
        if [ $? -eq 0 ]; then
            echo "Copiere cu succes in $DEST"
        else
            echo "Eroare la copierea in $DEST"
        fi
    done
}

# Funcție pentru a copia conținutul dezarhivat (întregul director lib) într-o singură destinație specificată prin argument
copy_to_custom_destination() {
    CUSTOM_DEST="$1"
    if [ ! -d "$CUSTOM_DEST" ]; then
        echo "Eroare: Directorul $CUSTOM_DEST nu există!"
        exit 1
    fi

    # Copiem întregul director lib în destinația custom
    echo "Copiaza întregul director lib in $CUSTOM_DEST"
    cp -rf lib "$CUSTOM_DEST"
    if [ $? -eq 0 ]; then
        echo "Copiere cu succes in $CUSTOM_DEST"
    else
        echo "Eroare la copierea in $CUSTOM_DEST"
    fi
}

# Funcție pentru a șterge fișierele temporare
clean_up() {
    echo "Ștergere fișiere temporare..."
    rm -rf "$PACKAGE_NAME" "lib"
    if [ $? -eq 0 ]; then
        echo "Fișiere temporare șterse cu succes."
    else
        echo "Eroare la ștergerea fișierelor temporare!"
    fi
}

# Verificăm dacă s-a primit un argument (o cale custom)
if [ $# -eq 1 ]; then
    download_if_not_exists
    extract_package
    copy_to_custom_destination "$1"
else
    download_if_not_exists
    extract_package
    copy_to_default_destinations
fi

# Ștergem fișierele temporare
clean_up

echo "Script finalizat."