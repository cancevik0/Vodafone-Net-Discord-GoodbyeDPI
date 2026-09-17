# Saha notları ve doğrulama sınırı

Bu profil Eylül 2026'da bir Vodafone Net / Windows bağlantısındaki Discord sorunundan çıkarıldı. Kişisel cihaz bilgileri ve loglar örneğe alınmadı.

| Gözlem | Çıkarımın sınırı |
| --- | --- |
| Modem DNS'i ile sorunlu yanıt; Quad9 ile kullanılabilir yanıt | Her Vodafone hattında aynı DNS sorunu olduğu anlamına gelmez |
| Seçilen GoodbyeDPI profiliyle Discord kullanılabildi | Güncelleyici, ses ve her Discord uç noktası için kapsamlı test değil |
| Güncelleme VPN ile tamamlandıktan sonra VPN kapalıyken uygulama çalıştı | Ana uygulama erişimi ile güncelleme erişimi ayrı değerlendirilmelidir |
| Alan adı listesi ve `-q` kaldırılması sonrasında da oyun PL şikâyeti sürdü | Alan adı sınırlaması tam süreç izolasyonu sağlamaz |
| GoodbyeDPI kapalıyken bir raid'de PL bildirilmedi | Kontrollü tekrarlı test yok; kök neden kanıtlanmadı |

## Güncelleme manifestini sabitleme deneyi

Dosyalar, veritabanı sorgusu, ayar değişikliği ve geri alma işlemi [Discord güncelleme deneyi](DISCORD-UPDATE.md) belgesinde açıklanmıştır.

Yerel Discord sürümünde `USE_PINNED_UPDATE_MANIFEST` ve `pinned_update.json` desteği bulunmuştu. Aynı cihazın daha önce başarıyla aldığı manifest kullanılarak güncelleme akışı sabitlendi. Bu, desteklenen ve kalıcı olduğu garanti edilen bir Discord özelliği değildir. Yeni sürümlerin ve güvenlik güncellemelerinin alınmasını engelleyebilir.

Bu nedenle repo bu ayarı otomatik etkinleştirmez, bir kullanıcıya ait manifest dağıtmaz ve Discord'un güncelleme sorununun genel olarak çözüldüğünü iddia etmez. Önceki deneyin geri alınması için Discord tamamen kapalıyken `settings.json` yedeklenip `USE_PINNED_UPDATE_MANIFEST` anahtarı kaldırılmıştı. Başka sürümlere körlemesine uygulanmamalıdır.

## macOS

Windows sürücüsü macOS'a taşınamaz. Kullanıcının paylaştığı SpoofDPI rehberi temel alınarak ayrı [macOS bölümü](macos.md) eklendi. Yeni otomasyonun Mac üzerinde uçtan uca doğrulaması bekleniyor.
