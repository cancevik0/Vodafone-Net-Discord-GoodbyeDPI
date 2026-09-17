# macOS: Discord için yerel proxy

Kaynak: kullanıcının paylaştığı **DiscordLocalDPI-macOS-Rehberi.txt**. Rehber macOS 26.6.2 / Apple Silicon arm64 / SpoofDPI 1.5.3 ve `/Applications/Discord.app` ile çalışan bir kurulum bildiriyor. Bu bilgi kullanıcı beyanıdır; bu repo hazırlanırken Mac üzerinde yeniden test yapılmadı. Intel için paket bulunması test edildiği anlamına gelmez.

## Çalışma mantığı

SpoofDPI `127.0.0.1:18080` üzerinde HTTP proxy olarak dinler. Discord `--proxy-server=http://127.0.0.1:18080` parametresiyle açılır. Proxy içindeki HTTPS parçalama işlemi özel `sites.txt` listesindeki hedeflerle sınırlandırılır. Liste dışı HTTPS bağlantıları proxy içinden standart TLS ile geçer. Bu parametre native ses/UDP ve güncelleyicinin tüm trafiğinin proxyye gireceğini garanti etmez; mesaj, güncelleme ve ses ayrı denenmelidir.

İki kullanıcı LaunchAgent'ı vardır: proxy sürekli çalışır; launcher proxy hazır olana kadar bekler, Discord yanlış parametreyle açıksa kapatıp yeniden açar. Aktif görüşme kesilebilir. Launcher başarılı çıkınca sürekli dönmez; Discord sonradan normal simgesinden açıldığında parametre eklenmeyebilir. Böyle bir durumda `restart` kullanın.

## Kaynak rehberden düzeltmeler

- `auto-configure-network=true` **sistem genelindeki proxy ayarını değiştirir**. Discord'a özel örnekte `false` seçildi. Bu davranış değişikliği Mac üzerinde yeniden doğrulanmalıdır. Eski kurulumun sistem proxy ayarları otomatik sıfırlanmaz.
- Intel paketinin adı `spoofdpi_1.5.3_darwin_x86_64.tar.gz`; `amd64` kullanılmaz.
- Kurulum özel listeyi korur. Liste yoksa temsili örnek oluşturur; düzenleme yapılabilmesi için servis başlatma ayrı komuttur.
- Plist yolları `plutil` ile yerleştirilir; boşluk ve XML özel karakterleri metin ikamesine bırakılmaz. Dizin ve dosyalar kullanıcıya özel izinlerle kurulur.

Kaynaklar: [sürüm dosyaları](https://github.com/xvzc/spoofdpi/releases/tag/v1.5.3), [sistem proxy ayarı](https://github.com/xvzc/spoofdpi/blob/v1.5.3/docs/user-guide/app.md), [alan adı kuralları](https://github.com/xvzc/spoofdpi/blob/v1.5.3/docs/user-guide/rules.md).

## Kurulum

Repo klasöründe Terminal açın. `sudo` kullanmayın; kendi grafik oturumunuzda çalıştırın. Discord `/Applications/Discord.app` altında olmalıdır.

```bash
bash macos/install-macos.sh
```

Betik mimariyi belirler, sabitlenmiş resmî sürümü ve `checksums.txt` dosyasını indirir; SHA256 eşleşmeden kurmaz. Bu kontrol aynı kaynaktan indirilen dosyaların tutarlılığını doğrular; ayrı yayıncı imzası doğrulaması değildir. Mevcut kurulumun üstüne sessizce yazılmaz. Gatekeeper engeli varsa resmî kaynağı doğruladıktan sonra macOS Gizlilik ve Güvenlik arayüzünü kullanın; betik güvenlik denetimlerini kapatmaz.

Dosyalar `~/Library/Application Support/DiscordLocalDPI/`, plist'ler `~/Library/LaunchAgents/` altına kurulur. **Temsili liste Discord erişimini sağlamaz.** Listeyi düzenleyin:

```bash
open -e "$HOME/Library/Application Support/DiscordLocalDPI/sites.txt"
```

Her satıra bir alan adı yazın; protokol, URL yolu veya port eklemeyin. Gereken alt alan adlarını da ekleyin; Windows listesinin alt alan adı davranışını varsaymayın. SpoofDPI wildcard kurallarını resmî belgelerden inceleyin. Kurucu ve servis betikleri mevcut listenin içeriğini okumaz veya loglamaz; proxy hedefleri uygulamak için listeyi çalışma sırasında okur.

Kaydettikten sonra:

```bash
bash macos/services-macos.sh start
bash macos/services-macos.sh status
```

LaunchAgent'lar kullanıcı oturum açılışında çalışır. Başlatma Discord'u kapatıp yeniden açabilir.

## Değişiklik ve kontrol

Liste değişikliğinden sonra:

```bash
bash macos/services-macos.sh restart
nc -z -w 1 127.0.0.1 18080
pgrep -x Discord | while read -r pid; do
  ps -ww -p "$pid" -o command=
done
```

Port kontrolü `0` başarı koduyla bitmeli; Discord komutunda `--proxy-server=http://127.0.0.1:18080` bulunmalı. Açık port erişim kanıtı değildir; mesaj, dosya ve ses ayrıca denenmelidir. Hata kayıtları kurulum klasöründeki `proxy.log` ve `launcher.log` dosyalarındadır. Loglar özel hedef adresleri içerebilir; paylaşmadan önce temizleyin.

## Durdurma, kaldırma ve yeniden kurma

```bash
bash macos/services-macos.sh stop
# Yeniden etkinlestirmek icin:
bash macos/services-macos.sh start
# Kaldirmak icin:
bash macos/services-macos.sh remove
```

`stop` oturum açılışını da devre dışı bırakır; `start` yeniden etkinleştirir. `remove` plist'leri, proxy ikilisini ve launcher betiğini kaldırır; **sites.txt, TOML ve loglar korunur**. Discord'u tamamen kapatıp normal simgesinden yeniden açın; aksi hâlde kapanmış proxyyi kullanmayı sürdürür.

Tekrar kurulumda mevcut liste korunur; TOML repo örneğinden yeniden oluşturulur. Özel TOML değişikliklerinizi önce yedekleyin. Kurulum yarıda kalırsa `remove` ile oluşturulan dosyaları kaldırıp tekrar deneyin. Bu servis adlarını kullanan başka bir kurulum varsa önce onu inceleyin.

Eski rehberin `auto-configure-network=true` seçeneği kullanılmışsa macOS ağ ayarlarının Proxy bölümünü ayrıca kontrol edin; bu betik eski sistem proxy ayarını geri almaz. Proxy içindeki Quad9 DNS seçimi macOS bağdaştırıcısının DNS'ini değiştirmez.

## Discord updater bypass durumu

**Bu Mac kurulumunda güncellemeyi atlayan veya sürümü sabitleyen bir işlem yoktur.** `discord-launch.sh`, proxy hazır olunca Discord'u `--proxy-server=http://127.0.0.1:18080` ile açar. Bu parametreyi updater bypass olarak değerlendirmeyin; güncelleyicinin tüm bağlantılarının bu proxyyi kullanacağı doğrulanmadı.

Paylaşılan kaynak Mac rehberinde `pinned_update.json`, güncelleme atlama ayarı veya ayrı bir updater işlemi bulunmuyor. Dolayısıyla Windows'ta gözlenen `USE_PINNED_UPDATE_MANIFEST` yöntemini Mac için çalışır bir çözüm olarak sunmuyoruz. Mac'te ayrıca uygulanmış bir yöntem varsa, sürümü ve geri alma adımları doğrulandıktan sonra bu bölüme eklenmelidir.

`Checking for updates` / `Update failed` ekranında kalıyorsa önce proxy ve launcher durumunu yukarıdaki komutlarla kontrol edin. Ana uygulamanın açılması, güncelleme sunucusuna erişimin de çalıştığını kanıtlamaz. Çalışan bir bağlantıda normal güncelleme tamamlandıktan sonra yerel proxy ile yeniden denenebilir; bu, kalıcı bir updater bypass değildir.

Windows için belgelenmiş deneyin ayrıntıları: [Discord updater bypass ve geri alma](DISCORD-UPDATE.md).

## Doğrulama sınırı

Gerçek launchd yükleme, Gatekeeper, oturum açılışı ve Discord bağlantısı bir Mac üzerinde ayrıca test edilmelidir. Windows güncelleme manifesti sabitlemesi macOS için uygulanmış veya doğrulanmış değildir. Projenin eğitim/araştırma amacı ve kullanım açıklaması bu bölüm için de geçerlidir.
