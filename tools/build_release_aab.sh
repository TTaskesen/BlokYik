#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR='/Users/turguttaskesen/GodotProjects/BlokYik'
readonly KEY_DIR='/Users/turguttaskesen/Library/Application Support/Blok Yık/keys'
readonly KEY_FILE="$KEY_DIR/blokyik-upload.jks"
readonly KEY_ALIAS='blokyik-upload'
readonly AAB_DIR='/Users/turguttaskesen/Desktop/Yayına Hazır Dosyalar/Blokyık'
readonly AAB_FILE="$AAB_DIR/BlokYik-v0.1.1-release.aab"
readonly JAVA_HOME_17='/Users/turguttaskesen/Library/Java/JavaVirtualMachines/jbr-17.0.14/Contents/Home'
readonly GODOT_BIN='/Applications/Godot.app/Contents/MacOS/Godot'

cleanup() {
  unset release_password release_password_check
}
trap cleanup EXIT INT TERM

mkdir -p "$KEY_DIR" "$AAB_DIR"

if [[ -e "$KEY_FILE" ]]; then
  read -r -s 'release_password?Mevcut Blok Yık upload anahtarı parolasını girin: '
  print
else
  read -r -s 'release_password?Yeni Blok Yık upload anahtarı parolasını girin: '
  print
  read -r -s 'release_password_check?Aynı parolayı tekrar girin: '
  print

  if [[ "$release_password" != "$release_password_check" ]]; then
    print -u2 'DURDURULDU: Parolalar eşleşmedi.'
    exit 4
  fi

  "$JAVA_HOME_17/bin/keytool" -genkeypair -v \
    -keystore "$KEY_FILE" \
    -storetype PKCS12 \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$release_password" \
    -keypass "$release_password" \
    -dname 'CN=Blok Yık Upload Key, OU=Mobile Apps, O=Taskesen, C=TR'
fi

GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEY_FILE" \
GODOT_ANDROID_KEYSTORE_RELEASE_USER="$KEY_ALIAS" \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$release_password" \
  "$GODOT_BIN" --headless --path "$PROJECT_DIR" \
  --export-release Android "$AAB_FILE"

"$JAVA_HOME_17/bin/jarsigner" -verify "$AAB_FILE"
ls -lh "$AAB_FILE"
print 'TAMAMLANDI: Release AAB imzalandı.'
