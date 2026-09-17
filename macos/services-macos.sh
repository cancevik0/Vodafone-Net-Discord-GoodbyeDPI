#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == Darwin && "$(id -u)" != 0 ]] || { echo 'macOS kullanici oturumu gerekir; sudo kullanmayin.' >&2; exit 1; }
DPI_DIR="$HOME/Library/Application Support/DiscordLocalDPI"
AGENTS_DIR="$HOME/Library/LaunchAgents"
USER_DOMAIN="gui/$(id -u)"
action="${1:-status}"
case "$action" in
  start)
    for kind in proxy launcher; do
      label="local.discord-dpi.$kind"
      plist="$AGENTS_DIR/$label.plist"
      plutil -lint "$plist" >/dev/null
      launchctl enable "$USER_DOMAIN/$label"
      if ! launchctl print "$USER_DOMAIN/$label" >/dev/null 2>&1; then
        launchctl bootstrap "$USER_DOMAIN" "$plist"
      fi
      launchctl kickstart "$USER_DOMAIN/$label"
    done
    echo 'Baslatma istendi. Durumu ve Discord baglantisini kontrol edin.'
    ;;
  restart)
    launchctl kickstart -k "$USER_DOMAIN/local.discord-dpi.proxy"
    launchctl kickstart -k "$USER_DOMAIN/local.discord-dpi.launcher"
    ;;
  stop|remove)
    for kind in launcher proxy; do
      label="local.discord-dpi.$kind"
      if launchctl print "$USER_DOMAIN/$label" >/dev/null 2>&1; then
        launchctl bootout "$USER_DOMAIN/$label"
      fi
      launchctl disable "$USER_DOMAIN/$label"
      if [[ "$action" == remove ]]; then rm -f -- "$AGENTS_DIR/$label.plist"; fi
    done
    if [[ "$action" == remove ]]; then
      rm -f -- "$DPI_DIR/spoofdpi" "$DPI_DIR/discord-launch.sh"
      echo 'Servisler kaldirildi; sites.txt, yapilandirma ve loglar korundu.'
    fi
    echo 'Discord acik kaldiysa tamamen kapatip normal simgesinden yeniden acin.'
    ;;
  status)
    for kind in proxy launcher; do
      launchctl print "$USER_DOMAIN/local.discord-dpi.$kind" || true
    done
    /usr/bin/nc -z -w 1 127.0.0.1 18080
    ;;
  *) echo 'Kullanim: services-macos.sh start|stop|restart|status|remove' >&2; exit 2 ;;
esac
