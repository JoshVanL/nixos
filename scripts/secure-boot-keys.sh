#!/usr/bin/env nix-shell
#! nix-shell -i bash -p efitools

# This scripts generates the keys and signatures for setting up Secure Boot.

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export BLUE_BG="\033[44m"

GUID=$(uuidgen --random)
DIR="/persist/etc/secure-boot"

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

info "Creating Secure Boot keys directory"
rm -rf $DIR/*
mkdir -p $DIR
cd $DIR
trap 'cd -' EXIT

info "Generating Secure Boot Platform Key"
openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=joshvanl Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$GUID" PK.crt PK.esl
sign-efi-sig-list -g "$GUID" -k PK.key -c PK.crt PK PK.esl PK.auth
# Sign an empty file to allow removing Platform Key when in "User Mode"
sign-efi-sig-list -g "$GUID" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

info "Generating Secure Boot Key Exchange Key"
openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=joshvanl Key Exchange Key/" -out KEK.crt
openssl x509 -outform DER -in KEK.crt -out KEK.cer
cert-to-efi-sig-list -g "$GUID" KEK.crt KEK.esl
sign-efi-sig-list -g "$GUID" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

info "Generating Secure Boot Signature Database Key"
openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=joshvanl Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$GUID" db.crt db.esl
sign-efi-sig-list -g "$GUID" -k KEK.key -c KEK.crt db db.esl db.auth
