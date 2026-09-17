#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == Darwin && "$(id -u)" != 0 ]] || { echo 'macOS kullanici oturumu gerekir; sudo kullanmayin.' >&2; exit 1; }
[[ -d /Applications/Discord.app ]] || { echo 'Discord /Applications altinda bulunamadi.' >&2; exit 1; }
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
DPI_DIR="$HOME/Library/Application Support/DiscordLocalDPI"
AGENTS_DIR="$HOME/Library/LaunchAgents"
case "$(uname -m)" in
  arm64) arch=arm64 ;;
  x86_64) arch=x86_64 ;;
  *) echo 'Desteklenmeyen mimari.' >&2; exit 1 ;;
esac
for path in "$DPI_DIR/spoofdpi" "$AGENTS_DIR/local.discord-dpi.proxy.plist" "$AGENTS_DIR/local.discord-dpi.launcher.plist"; do
  [[ ! -e "$path" ]] || { echo 'Mevcut kurulum bulundu; once kaldirma rehberini izleyin.' >&2; exit 1; }
done
if /usr/bin/nc -z -w 1 127.0.0.1 18080 >/dev/null 2>&1; then
  echo '18080 portu kullanimda.' >&2; exit 1
fi
version=1.5.3
asset="spoofdpi_${version}_darwin_${arch}.tar.gz"
base="https://github.com/xvzc/spoofdpi/releases/download/v${version}"
stage="$(mktemp -d "${TMPDIR:-/tmp}/acik-hat.XXXXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
umask 077
curl --fail --location --proto '=https' --tlsv1.2 "$base/$asset" -o "$stage/$asset"
curl --fail --location --proto '=https' --tlsv1.2 "$base/checksums.txt" -o "$stage/checksums.txt"
expected="$(awk -v name="$asset" '$2 == name || $2 == "*"name {print $1}' "$stage/checksums.txt")"
[[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || { echo 'SHA256 kaydi bulunamadi.' >&2; exit 1; }
actual="$(shasum -a 256 "$stage/$asset" | awk '{print $1}')"
[[ "$actual" == "$expected" ]] || { echo 'SHA256 uyusmuyor.' >&2; exit 1; }
mkdir "$stage/unpacked"
tar -xzf "$stage/$asset" -C "$stage/unpacked"
[[ -f "$stage/unpacked/spoofdpi" ]] || { echo 'Arsivde spoofdpi yok.' >&2; exit 1; }
mkdir -p "$DPI_DIR" "$AGENTS_DIR"
cp "$stage/unpacked/spoofdpi" "$DPI_DIR/spoofdpi"
cp "$stage/unpacked/LICENSE" "$DPI_DIR/LICENSE-SpoofDPI"
cp "$SOURCE_DIR/spoofdpi.toml" "$SOURCE_DIR/discord-launch.sh" "$DPI_DIR/"
if [[ ! -e "$DPI_DIR/sites.txt" ]]; then
  cp "$SOURCE_DIR/sites.txt.example" "$DPI_DIR/sites.txt"
fi
chmod 700 "$DPI_DIR" "$DPI_DIR/spoofdpi" "$DPI_DIR/discord-launch.sh"
chmod 600 "$DPI_DIR/spoofdpi.toml" "$DPI_DIR/sites.txt"
for kind in proxy launcher; do
  plist="$AGENTS_DIR/local.discord-dpi.$kind.plist"
  cp "$SOURCE_DIR/launchagents/local.discord-dpi.$kind.plist.template" "$plist"
  if [[ "$kind" == proxy ]]; then
    plutil -replace ProgramArguments.0 -string "$DPI_DIR/spoofdpi" "$plist"
    plutil -replace ProgramArguments.2 -string "$DPI_DIR/spoofdpi.toml" "$plist"
  else
    plutil -replace ProgramArguments.1 -string "$DPI_DIR/discord-launch.sh" "$plist"
  fi
  plutil -replace StandardOutPath -string "$DPI_DIR/$kind.log" "$plist"
  plutil -replace StandardErrorPath -string "$DPI_DIR/$kind.log" "$plist"
  plutil -lint "$plist"
  chmod 600 "$plist"
done
echo 'Dosyalar kuruldu; servisler henuz baslatilmadi.'
echo 'Once ozel sites.txt listenizi duzenleyin. Ardindan:'
echo 'bash macos/services-macos.sh start'
