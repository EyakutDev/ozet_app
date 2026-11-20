# Hata Yonetimi

Uygulamadaki hatalar `AppFailure` ile siniflandirilir. Kullaniciya Firebase veya
sunucu ayrintisi gosterilmez; teknik baglam `AppLogger` uzerinden kaydedilir.

## Karar tablosu

| Hata turu | Kullanici davranisi | Uygulama davranisi | Crashlytics |
| --- | --- | --- | --- |
| Baglanti / zaman asimi | Tekrar dene | Bir kontrollu tekrar, sonra varsa onbellek | Breadcrumb |
| Servis gecici kapali | Tekrar dene | Islemi durdur, mevcut veriyi koru | Non-fatal |
| Oturum suresi doldu | Giris yap | Kullanici giris ekranina yonlendirilir | Beklenen hata, raporlanmaz |
| Yetki reddi | Eylem sunma | Islemi durdur | Non-fatal |
| Gecersiz bilgi / kod | Bilgiyi duzelt | Tekrar gonderme yapma | Beklenen hata, raporlanmaz |
| Yerel kayit hatasi | Tekrar dene | Ekrandaki mevcut durumu koru | Non-fatal |
| Beklenmeyen hata | Tekrar dene | Islemi guvenli bicimde sonlandir | Non-fatal |
| Yakalanmamis Flutter/platform hatasi | Genel hata durumu | Global handler yakalar | Fatal |

## Kayit kurallari

- Her kayitta `operation`, hata `code`, hata `kind` ve onerilen `recovery` bulunur.
- E-posta, haber metni, gun notu, eslesme kodu, FCM tokeni ve diger kullanici
  icerikleri loglanmaz.
- Debug surumunde kayitlar `[OZET]` etiketiyle konsola yazilir. Crashlytics
  gonderimi yalnizca release surumlerinde aciktir.
- Beklenen kullanici hatalari Crashlytics issue listesine gonderilmez; yalnizca
  akisi anlamaya yarayan breadcrumb olarak tutulur.

## Hata aninda inceleme sirasi

1. Crashlytics'te etkilenen surumu, cihaz sayisini ve ilk gorulme zamanini kontrol et.
2. `last_operation` ve `last_error_code` alanlariyla bozulan akisi belirle.
3. Sorunun tek kullaniciya mi, tek surume mi, yoksa tum kullanicilara mi ait
   oldugunu ayir.
4. Veri kaybi veya giris engeli varsa yayini durdur; gecici servis hatasinda
   onbellek ve tekrar deneme sonucunu izle.
5. Duzeltmeyi ilgili `AppFailure` politika testi ve akisin widget testiyle sabitle.
