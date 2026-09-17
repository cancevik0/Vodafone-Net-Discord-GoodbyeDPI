# Açık Hat

**Windows için GoodbyeDPI, macOS için Discord'a özel SpoofDPI kurulumu. Vodafone Net üzerinde çalışan yapılandırmalardan doğan topluluk projesi.**

VPN aboneliği veya uzaktaki bir proxy sunucusu gerektirmez. Resmî GoodbyeDPI paketini indirir; seçtiğiniz alan adları için mevcut profili Windows servisi olarak çalıştırır.

## Kullanım amacı

Bu proje **yalnızca eğitim ve araştırma amaçlı** yayımlanmıştır: ağ davranışlarını incelemek, bağlantı sorunlarını anlamak ve deneyleri belgelemek için hazırlanmıştır. Kullanıcılar geçerli mevzuatı, hizmet koşullarını ve bulundukları ağın kullanım kurallarını gözetmelidir. Bu açıklama hukuki uygunluk veya sorumluluktan muafiyet garantisi değildir. Proje herhangi bir kurumun onayını veya her bağlantıda çalışma garantisini taşımaz.

> **Durum: örnek repo.** Kaynak Windows ve Mac kurulumlarında Discord erişimi bildirildi. Bu repo için hazırlanmış kurulum otomasyonları temiz makinelerde uçtan uca denenmedi. Her Vodafone hattında çalışacağı veya oyunlarda paket kaybını önleyeceği garanti edilmez.

## Platformlar

| Platform | Durum |
| --- | --- |
| Windows 10/11 x64 | Kurulum ve servis yönetimi örneği hazır |
| Windows ARM64 | Desteklenmiyor |
| macOS Apple Silicon / Intel | SpoofDPI rehberi ve kurulum betikleri hazır; kaynak deneyim Apple Silicon |

Mac kullanıyorsanız doğrudan [macOS kurulum rehberine](docs/macos.md) geçin. Aşağıdaki komutlar Windows içindir.

## Discord updater bypass / güncelleme ekranında takılma

Discord'un ana bağlantısı ile açılıştaki güncelleme kontrolü ayrı sorunlardır. DPI kurulumu tek başına güncelleme ekranını atlamaz.

| Platform | Yöntem ve anlatım |
| --- | --- |
| Windows | Yerel önbellekteki geçerli manifesti `pinned_update.json` olarak kaydedip `USE_PINNED_UPDATE_MANIFEST` ayarıyla sabitleme. [Adım adım uygulama ve geri alma](docs/DISCORD-UPDATE.md). Kaynak Discord 1.0.9257 kurulumunda denenmiştir. |
| macOS | Bu repodaki launcher yalnızca Discord'u yerel proxy ile açar; updater bypass uygulamaz. [Mac güncelleyicisi ve mevcut yöntemin sınırı](docs/macos.md#discord-updater-bypass-durumu). Paylaşılan Mac kurulum rehberinde ayrı bir bypass işlemi belgelenmemiştir. |

Windows'taki sabitleme yeni güvenlik güncellemelerini de durdurabilir; normal güncelleme erişimi sağlanınca geri alınmalıdır. Windows manifestini veya ayarını doğrulamadan Mac'e taşımayın.

## Windows hızlı başlangıç

PowerShell 5.1 veya üzeri gerekir. Repoyu indirip sabit bir klasöre çıkarın. Komutları repo klasöründe çalıştırın.

**1. Resmî paketi indirin:**

```powershell
.\windows\Manage.ps1 -Action Prepare
```

Bu adım sabitlenmiş `0.2.3rc3` sürümünü indirir ve arşivin SHA256 değerini doğrular. Güncel sürümü kendiliğinden seçmez. Dosyalar Git'e eklenmeyen `windows/.runtime/` klasöründe tutulur.

**2. [sites.txt](sites.txt) dosyasını düzenleyin.** Discord alan adları başlangıç listesinde bulunur. Her satıra bir alan adı veya tam HTTP/HTTPS adresi yazabilirsiniz:

```text
discord.com
example.org
https://www.example.net/sayfa
```

Tam adresten yalnızca alan adı alınır; `/sayfa` gibi yollar ayrı filtrelenmez. `example.org` alt alan adlarını da kapsar. `#` ile başlayan satırlar yorumdur. Boş veya geçersiz liste reddedilir. Değişikliklerin önizlemesi:

```powershell
.\windows\Manage.ps1 -Action Validate
```

**3. Yönetici olarak açtığınız PowerShell'de kurun:**

```powershell
.\windows\Manage.ps1 -Action Install
.\windows\Manage.ps1 -Action Status
```

Program ve işlenmiş liste `%ProgramFiles%\AcikHat` altına kopyalanır. `GoodbyeDPI` servisi otomatik başlangıçla kurulur. Başka bir GoodbyeDPI kurulumu varsa üzerine yazılmaz; önce eski kurulumu kendi kaldırma yöntemiyle kaldırmanız gerekir.

Windows indirdiğiniz betiği engellerse kodu inceleyip yalnızca bu dosyanın engelini kaldırabilirsiniz:

```powershell
Unblock-File .\windows\Manage.ps1
```

Kurumsal yürütme politikası betik çalıştırmaya izin vermiyorsa yöneticinize başvurun. Bu proje yürütme politikasını değiştirmez.

## Günlük kullanım

`sites.txt` dosyasını düzenledikten sonra **yönetici PowerShell** ile:

```powershell
.\windows\Manage.ps1 -Action Apply
```

Yeni liste doğrulanıp kurulum klasörüne kopyalanır. Servis çalışıyorsa kısa süreli yeniden başlatılır; kapalıysa kapalı bırakılır. Bu sırada aktif bağlantılar etkilenebilir.

| İşlem | Komut |
| --- | --- |
| Durumu gör | `.\windows\Manage.ps1 -Action Status` |
| Durdur | `.\windows\Manage.ps1 -Action Stop` |
| Yeniden aç | `.\windows\Manage.ps1 -Action Start` |
| Servisi kaldır | `.\windows\Manage.ps1 -Action Remove` |

`Status` dışındaki bu işlemler yönetici yetkisi ister. `Stop` yalnızca mevcut çalışmayı durdurur; bilgisayar yeniden açılınca servis başlar. `Remove` otomatik başlangıcı da kaldırır; program dosyalarını inceleyebilmeniz için diskte bırakır. Kaldırdıktan sonra `%ProgramFiles%\AcikHat` klasörünü elle silebilirsiniz. DNS ayarları bu araç tarafından değiştirilmediğinden kaldırma sırasında da değiştirilmez.

## Ne yapıyor?

Kullanılan profil:

```text
-e 2 --native-frag --frag-by-sni --wrong-seq --fake-resend 5 --blacklist sites.txt
```

GoodbyeDPI'daki `--blacklist` adı yanıltıcı olabilir: burada engellenecek siteleri değil, DPI aşma işlemi uygulanacak HTTP Host / TLS SNI alan adlarını belirtir. Global QUIC engelleyen `-q` kullanılmaz. Ayrıntılar: [resmî GoodbyeDPI belgeleri](https://github.com/ValdikSS/GoodbyeDPI#how-to-use).

**Bu, uygulama bazında kesin bir ayrım değildir.** WinDivert sistem seviyesinde çalışır. Listeyi Discord ile sınırlandırmak, başka uygulamaların hiç etkilenmeyeceğini garanti etmez. IP'niz değişmez; VPN'in gizlilik özelliklerini sağlamaz.

## DNS, Discord güncelleyicisi ve oyunlar

- **DNS:** Kaynak bağlantıda modem DNS'i yanlış adres döndürüyordu; Quad9 kullanılması ayrıca gerekli oldu. Bu repo DNS'i otomatik değiştirmez. Doğru DNS yanıtı almak tek başına DPI engelini çözmez. [Tanılama rehberi](docs/TROUBLESHOOTING.md).
- **Discord güncellemesi:** Ana uygulama çalışırken güncelleyici ayrı bir bağlantıda takılabilir. Yerel kurulumda kullanılan deneysel manifest sabitlemesi otomatik kurulumun parçası değildir. [Nasıl yaptık? Uygulama ve geri alma adımları](docs/DISCORD-UPDATE.md).
- **Tarkov / paket kaybı:** Önce servisi durdurup karşılaştırın. Kaynak bağlantıda servis kapalıyken bir raid sorunsuz geçti; bu tek başına nedeni kanıtlamaz. Oyunların kesin olarak ayrıştırıldığı iddia edilmez.

## Repo yapısı

```text
sites.txt                 Kullanıcının düzenlediği site listesi
windows/Manage.ps1        İndirme, kurulum, liste ve servis yönetimi
tests/Validate.Tests.ps1  Sistemi değiştirmeyen liste testleri
docs/                    Tanılama ve saha notları
macos/README.md          macOS çalışmasının durumu
```

## Katkı ve kaynaklar

Sorun bildirirken Windows sürümü, ISS, kullanılan profil ve hangi adımın başarısız olduğunu yazın. Token, özel mesaj, Wi-Fi parolası, tam Discord ayarları veya kişisel loglar paylaşmayın. [Katkı rehberi](CONTRIBUTING.md).

Asıl DPI motoru [ValdikSS/GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI), paket yakalama bileşeni [WinDivert](https://reqrypt.org/windivert.html) projesidir. Açık Hat bu projelerin resmî ürünü değildir; Vodafone veya Discord ile bağlantılı değildir. Bu repo kurulum betikleri ve belgelerini içerir; üçüncü taraf ikilileri Git'e eklemez.

Repo kodu [MIT lisansı](LICENSE) kapsamındadır. İndirilen üçüncü taraf bileşenler kendi lisanslarına tabidir; kurulum bunların lisans dosyalarını da saklar. [Bağımlılık bilgileri](THIRD_PARTY.md).
