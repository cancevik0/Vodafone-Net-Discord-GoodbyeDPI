#!/bin/bash

set -euo pipefail

echo "$(date '+%Y-%m-%d %H:%M:%S') Discord başlangıç kontrolü"

# Proxy'nin açılmasını en fazla 30 saniye bekle.
for attempt in {1..30}; do
  if /usr/bin/nc -z -w 1 127.0.0.1 18080 >/dev/null 2>&1; then
    break
  fi

  /bin/sleep 1
done

/usr/bin/nc -z -w 1 127.0.0.1 18080 >/dev/null 2>&1 || {
  echo 'Yerel proxy henüz hazır değil; launchd tekrar deneyecek.'
  exit 1
}

# Discord doğru proxy parametresiyle zaten açıksa yeniden açma.
# Normal şekilde açılmışsa önce kapat.
while IFS= read -r pid; do
  [[ -n "$pid" ]] || continue

  cmd="$(/bin/ps -ww -p "$pid" -o command= || true)"

  case "$cmd" in
    '/Applications/Discord.app/Contents/MacOS/Discord --proxy-server=http://127.0.0.1:18080'*)
      exit 0
      ;;
    */Discord.app/Contents/MacOS/Discord*)
      /bin/kill -TERM "$pid"
      ;;
  esac
done < <(/usr/bin/pgrep -x Discord || true)

# Eski Discord işleminin kapanmasını bekle.
for attempt in {1..30}; do
  if ! /usr/bin/pgrep -x Discord >/dev/null; then
    break
  fi

  /bin/sleep 0.2
done

if /usr/bin/pgrep -x Discord >/dev/null; then
  echo 'Mevcut Discord kapanmadı; ikinci kopya açılmadı.'
  exit 1
fi

/usr/bin/open /Applications/Discord.app \
  --args \
  --proxy-server=http://127.0.0.1:18080

# Discord'un doğru parametreyle açıldığını doğrula.
for attempt in {1..30}; do
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue

    cmd="$(/bin/ps -ww -p "$pid" -o command= || true)"

    case "$cmd" in
      '/Applications/Discord.app/Contents/MacOS/Discord --proxy-server=http://127.0.0.1:18080'*)
        echo 'Discord doğru bağlantı parametresiyle açıldı.'
        exit 0
        ;;
    esac
  done < <(/usr/bin/pgrep -x Discord || true)

  /bin/sleep 1
done

echo 'Discord doğru parametreyle doğrulanamadı; launchd tekrar deneyecek.'
exit 1
