#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR='/Users/turguttaskesen/GodotProjects/BlokYik'
readonly KEY_DIR='/Users/turguttaskesen/Library/Application Support/Blok Yık/keys'
readonly KEY_FILE="$KEY_DIR/blokyik-upload.jks"
readonly KEY_ALIAS='blokyik-upload'
readonly AAB_DIR='/Users/turguttaskesen/Desktop/Yayına Hazır Dosyalar/Blokyık'
readonly JAVA_HOME_17='/Users/turguttaskesen/Library/Java/JavaVirtualMachines/jbr-17.0.14/Contents/Home'
readonly GODOT_BIN='/Applications/Godot.app/Contents/MacOS/Godot'
readonly EXPORT_PRESET="$PROJECT_DIR/export_presets.cfg"

read_preset_value() {
  local key="$1"
  /usr/bin/awk -F= -v wanted="$key" '
    /^\[preset\.0\.options\]$/ { in_options=1; next }
    /^\[/ { in_options=0 }
    in_options && $1 == wanted {
      value=substr($0, index($0, "=") + 1)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$EXPORT_PRESET"
}

if [[ ! -r "$EXPORT_PRESET" ]]; then
  print -u2 "DURDURULDU: Android export preset okunamadı: $EXPORT_PRESET"
  exit 2
fi

readonly VERSION_NAME="$(read_preset_value 'version/name')"
readonly VERSION_CODE="$(read_preset_value 'version/code')"
if [[ -z "$VERSION_NAME" || "$VERSION_NAME" != <->.<->.<-> || -z "$VERSION_CODE" || "$VERSION_CODE" != <-> ]]; then
  print -u2 'DURDURULDU: export_presets.cfg içindeki version/name veya version/code geçersiz.'
  exit 3
fi

readonly AAB_FILE="$AAB_DIR/BlokYik-v${VERSION_NAME}-release.aab"
readonly PARTIAL_AAB_FILE="${AAB_FILE}.partial.$$"

cleanup() {
  unset release_password release_password_check
  if [[ -f "$PARTIAL_AAB_FILE" ]]; then
    /bin/rm -f -- "$PARTIAL_AAB_FILE"
  fi
}
trap cleanup EXIT INT TERM

print "Sürüm: ${VERSION_NAME} (versionCode ${VERSION_CODE})"
print "Çıktı: $AAB_FILE"

if [[ "${1:-}" == '--print-output' ]]; then
  exit 0
fi

if [[ -e "$AAB_FILE" ]]; then
  print -u2 "DURDURULDU: Hedef AAB zaten var; üzerine yazılmadı: $AAB_FILE"
  exit 5
fi

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
	  --export-release Android "$PARTIAL_AAB_FILE"

"$JAVA_HOME_17/bin/jarsigner" -verify "$PARTIAL_AAB_FILE"
if [[ -e "$AAB_FILE" ]]; then
  print -u2 "DURDURULDU: Export sırasında hedef AAB oluştu; üzerine yazılmadı: $AAB_FILE"
  exit 6
fi
/bin/mv -- "$PARTIAL_AAB_FILE" "$AAB_FILE"
ls -lh "$AAB_FILE"
print 'TAMAMLANDI: Release AAB imzalandı.'
