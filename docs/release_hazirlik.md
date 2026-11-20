# Release Hazirligi

## Android imzalama

Uretim paketi debug anahtariyla imzalanmaz. `android/key.properties.example`
dosyasini `android/key.properties` olarak olustur ve gercek upload keystore
bilgilerini gir. Keystore ile `key.properties` Git tarafindan yok sayilir.

Gerekli alanlar:

- `storeFile`: `android` klasorune gore keystore yolu
- `storePassword`: keystore sifresi
- `keyAlias`: upload anahtarinin adi
- `keyPassword`: upload anahtarinin sifresi

Bu dosya yokken debug build calisir; release build guvenlik nedeniyle durur.

## Paket kimligi

Mevcut Android kimligi `com.example.ozet_app`, iOS kimligi ise
`com.example.ozetApp`. Magaza yayinindan once kalici kimlik kararlastirilmalidir.
Kimlik degistirilirken ayni anda su islemler yapilmalidir:

1. Firebase Console'da yeni Android ve iOS uygulamalarini ekle.
2. Yeni `google-services.json` ve `GoogleService-Info.plist` dosyalarini indir.
3. Google Sign-In SHA-1/SHA-256 degerlerini yeni Android uygulamasina ekle.
4. Android namespace, Kotlin paket yolu ve iOS bundle identifier degerlerini guncelle.
5. Giris, bildirim ve Crashlytics akisini internal release ile dogrula.

Firebase uygulamalari olusturulmadan yalnizca kod tarafinda kimlik degistirmek
Google girisini ve bildirimleri bozar.
