# Discord güncelleme kontrolünü sabitleme deneyi

Bu belge eğitim ve araştırma amacıyla, kaynak Windows kurulumunda yapılan işlemi açıklar. Repo kurucusu bu işlemi otomatik uygulamaz. Discord'un desteklediği genel bir kurulum yöntemi olarak sunulmaz.

## Hangi sorunu gözlemledik?

Discord masaüstü uygulaması güncelleme ekranında takılıyordu. Bir defa erişim sağlanıp güncelleme tamamlandıktan sonra, VPN kapalı ve GoodbyeDPI açıkken ana uygulama kullanılabiliyordu. Bu nedenle uygulamanın erişimi ile güncelleyicinin erişimini ayrı ele aldık.

Windows Discord `1.0.9257` sürümündeki yerel uygulama kodunda `USE_PINNED_UPDATE_MANIFEST` ayarı ve `pinned_update.json` dosyasını okuyan yol bulundu. Yerel önbellekte daha önce başarıyla alınmış güncelleme manifesti vardı. Güncelleyicinin bu manifesti kullanması sağlandı.

Buradaki “update bypass”, güncelleyiciye kullanılacak manifesti sabitlemek anlamındadır. Discord program dosyası veya imza kontrolü değiştirilmedi, TLS sertifika doğrulaması kapatılmadı. Bu işlem ana uygulamanın ağ engelini kaldırmaz ve eksik modüllerin indirilmesini gereksiz hâle getirmez.

## Kullanılan dosyalar

| Konum | İşlev |
| --- | --- |
| `%LOCALAPPDATA%\Discord\installer.db` | Güncelleyicinin yerel SQLite veritabanı |
| `%APPDATA%\discord\settings.json` | Kullanıcının Discord ayarları |
| `%APPDATA%\discord\pinned_update.json` | Yerel önbellekten çıkarılan sabit manifest |

Bu yollar Windows'un standart Discord kanalına aittir. PTB, Canary, macOS veya başka sürümlerde aynı yöntemin geçerli olduğu doğrulanmadı.

## Kaynak kurulumda nasıl uygulandı?

1. Discord tamamen kapatıldı; arka planda `Discord.exe` kalmadığı kontrol edildi. `settings.json` yedeklendi. Varsa önceki `pinned_update.json` da korunmalıdır.
2. `installer.db` SQLite veritabanı **salt okunur** açıldı. Yalnızca aşağıdaki anahtarın `value` alanı okundu:

   ```sql
   SELECT value
   FROM key_values
   WHERE key = 'latest/host/app/stable/win/x64';
   ```

3. Dönen JSON'un `full.host_version` alanı incelendi; kaynak cihazda `[1, 0, 9257]` idi. Bunun aynı cihazda kurulu, daha önce güncellemesi tamamlanmış sürümle eşleştiği kontrol edildi. Manifest bulunmuyorsa, JSON geçersizse veya kurulu sürümle uyuşmuyorsa bu adım uygulanmamalıdır. Başka bir kullanıcının manifesti kullanılmamalıdır.
4. Sorgudan dönen **JSON değerinin tamamı**, dışına yeni bir alan eklenmeden ve yalnızca `full` kısmına indirgenmeden, UTF-8 olarak `%APPDATA%\discord\pinned_update.json` dosyasına yazıldı. Veritabanının kendisi değiştirilmedi.
5. Mevcut `settings.json` içindeki diğer ayarlar korunarak üst seviyeye şu alan eklendi:

   ```json
   "USE_PINNED_UPDATE_MANIFEST": true
   ```

   Bu satır tek başına tam bir JSON dosyası değildir. Mevcut nesneye eklenirken virgüller ve JSON biçimi korunmalıdır; dosyanın tamamını bu satırla değiştirmeyin.

6. Discord yeniden açıldı. Kaynak uygulama kodunun yerel manifesti okuyup güncelleyiciye `SetManifests` / `Pinned` akışıyla ilettiği belirlendi; açılış kayıtlarında uygulamayı başlatma aşamasına geçildiği gözlendi.

Bu yöntemle her sürümde çalışacağı doğrulanmamış `SKIP_HOST_UPDATE`, `SKIP_MODULE_UPDATE` veya `USE_NEW_UPDATER` gibi başka bayraklar eklenmedi. Yalnızca bir ayar adını eklemek, o sürümün bu ayarı desteklediğini kanıtlamaz.

## Geri alma ve normal güncellemeye dönme

1. Discord'u tamamen kapatın.
2. Güncel `settings.json` dosyasını yedekleyin.
3. Yalnızca `USE_PINNED_UPDATE_MANIFEST` alanını kaldırın; diğer ayarları ve geçerli JSON biçimini koruyun.
4. Deney sırasında oluşturulan `pinned_update.json` dosyasını yedek olarak yeniden adlandırabilirsiniz. Önceden başka bir sabitleme ayarı varsa onu kendi yedeğinden değerlendirin.
5. Güncelleme sunucularına erişimin çalıştığı bağlantıda Discord'u yeniden açıp normal güncellemeyi tamamlayın.

**Sabitleme yeni sürüm ve güvenlik güncellemelerinin alınmasını engelleyebilir.** Kalıcı bir “bir kez yap, unut” ayarı olarak kullanılmamalıdır. Güncelleme erişimi düzeldiğinde normal akışa dönülmelidir. Bu deney ses bağlantısı, mesaj erişimi veya oyun performansı sorunlarını tek başına çözmez.

## Neden manifesti repoya koymuyoruz?

Manifest belirli bir kanal, mimari, sürüm ve modül durumuna bağlıdır. Aynı JSON'u herkese dağıtmak uygun değildir. `installer.db`, `settings.json`, kişisel manifest ve loglar bu repoya eklenmez; `.gitignore` yaygın dosya adlarını dışlar. Hata bildirirken yalnızca kişisel bilgilerden temizlenmiş hata metni paylaşılmalıdır.
