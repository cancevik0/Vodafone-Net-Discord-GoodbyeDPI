# Bağlantı tanılama

Önce `windows/Manage.ps1 -Action Status` ile servisin durumunu kontrol edin. Yeni eklediğiniz sitelerin uygulanması için `Apply` gerekir. Repo klasöründeki `sites.txt` doğrudan canlı okunmaz.

## DNS yanıtı ile HTTPS bağlantısını ayırın

```powershell
Resolve-DnsName discord.com
Resolve-DnsName discord.com -Server 9.9.9.9
curl.exe --connect-timeout 5 --max-time 15 -I https://discord.com
```

İki DNS sunucusunun farklı IP döndürmesi tek başına engel kanıtı değildir; CDN'ler farklı adresler verebilir. Beklenmedik engelleme adresi, sertifika hatası ve HTTPS sonuçlarını birlikte değerlendirin. TLS sertifika doğrulamasını kapatmayın.

Kaynak kurulumda Quad9 (`9.9.9.9`, IPv6 `2620:fe::fe`) kullanıldı. DNS değiştirecekseniz önce bağdaştırıcının mevcut otomatik/statik ayarlarını kaydedin ve [Quad9'un resmî kurulum rehberini](https://docs.quad9.net/) izleyin. IPv6 DNS'i modeme ait kalıyorsa bunu ayrıca kontrol edin. Kaynak makinedeki RA DNS değişikliği herkes için gerekli değildir; bu repo IPv6'yı veya RA DNS'i kapatmaz.

## Discord açılıyor ama güncellemede takılıyor

Güncelleyici ile uygulama aynı ağ yolunu/TLS davranışını kullanmayabilir. DNS ve genel bir HTTP 200 sonucu, güncelleyicinin çalıştığını kanıtlamaz. Discord'u tamamen kapatıp yeniden deneyin; devam ederse güncelleme uç noktasındaki hatayı ayrıca araştırın. Kişisel `settings.json`, `installer.db` veya manifest dosyalarını issue'ya yüklemeyin.

## Oyunlarda yüksek ping veya paket kaybı

Yönetici PowerShell'de `Stop` ile servisi durdurun. Mümkünse aynı sunucu ve benzer koşullarda servis açık/kapalı karşılaştırması yapın. Otomatik bölge seçimi başka sunucuya taşıyabilir; iki farklı raid kesin karşılaştırma değildir. Aynı anda Wi-Fi, modem ve ISS rotasını da değerlendirin. DNS'i değiştirmiş olmanız, oyunun tüm paketlerinin DNS üzerinden geçtiği anlamına gelmez.

## Kurulum yarıda kaldı

`Status` ile kayıt oluşup oluşmadığını kontrol edin. Bu repo tarafından oluşturulan servis varsa `Remove` kullanın. Dosyalar korunduğu için yeniden kurmadan önce `%ProgramFiles%\AcikHat` klasörünü inceleyip yeniden adlandırın veya kaldırın. Başka kurulumlara ait servis ve sürücüleri zorla silmeyin.

## Site hâlâ açılmıyor

Site farklı CDN veya oturum açma alan adlarına ihtiyaç duyabilir. Gerekli alan adlarını belirleyip listeye ekleyin. Şifreli SNI, farklı protokoller, IP tabanlı engeller ve ISS değişiklikleri bu profili etkileyebilir. `sites.txt` tüm türde engelleri çözmez.
