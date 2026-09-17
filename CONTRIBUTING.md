# Katkı

Profil değişikliklerini önce açık/kapalı karşılaştırmasıyla deneyin. Başarı bildiriminde ISS, işletim sistemi, sürüm ve test edilen özelliği belirtin: mesajlar, dosya indirme, ses veya güncelleme. Tek bir site yanıtını tüm sistemin çalıştığı şeklinde raporlamayın.

Betik kontrolleri:

```powershell
.\tests\Validate.Tests.ps1
```

Bu testler servis kurmaz veya DNS değiştirmez. Kurulum değişiklikleri için ayrıca temiz bir Windows x64 sanal makinesinde Prepare → Install → Apply → Stop → Start → Remove döngüsünü, yeniden başlatmada otomatik başlangıcı ve boşluk içeren dizinleri deneyin. Mevcut GoodbyeDPI kurulumunun devralınmadığını doğrulayın.

Kişisel site listelerinizi, bağlantı loglarınızı ve Discord verilerinizi commit öncesinde kontrol edin. Varsayılan liste yalnızca Discord alan adlarını içerir.
