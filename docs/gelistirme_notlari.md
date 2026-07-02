# Ozet App Gelistirme Notlari

Bu dokuman, uygulamada yaptigimiz tasarim ve davranis degisikliklerini takip etmek icin tutulur. Yeni bir ozellik, tasarim karari veya onemli refactor yapildiginda burasi guncellenecek.

## Uygulama Ozeti

Ozet App, Firebase tabanli bir Flutter haber/ozet uygulamasidir.

- Kullanici Firebase Auth ile e-posta/sifre veya Google hesabi ile giris yapar.
- Splash ekrani mevcut oturuma gore kullaniciyi ana sayfaya veya auth ekranina yonlendirir.
- Ana sayfa Firestore `news` koleksiyonundan haberleri, `live_data/finance` dokumanindan finans verilerini okur.
- Haberler admin panelinden manuel eklenen alanlarla calisir: `title`, `summary`, `detail`, `source`, `createdAt`.
- Partner/eslesme ozelligi Firestore `users` dokumanlari uzerinden calisir.
- Tema secimi ve bildirim tercihleri `SharedPreferences` ile cihazda saklanir.

## Yapilan Degisiklikler

### Auth Ekrani

- Giriş/Kayit ekrani modernlestirildi.
- Giriş/Kayit gecisi tek parca kayan segment bara donusturuldu.
- Google girisi logo yerine buton olarak tasarlandi.
- Sifre goster/gizle ozelligi eklendi.
- Sifremi unuttum Firebase password reset akisina baglandi.
- Gelistirme icin gecici `Şimdilik giriş yapmadan devam et` butonu eklendi.

### Ana Sayfa Haber Kartlari

- Haber kartlari modern kart tasarimina tasindi.
- Kaynak etiketi kartin ust alaninda chip olarak gosteriliyor.
- `createdAt` varsa tarih gosteriliyor, yoksa gizleniyor.
- Kartlar artik normal tiklama ile detay acar.
- `detail` alani bossa detay ekraninda `summary` gosterilir.
- Kartlar ile haber listesi arasindaki bosluk azaltildi.
- Ana sayfada artik kullanilmayan eski haber karti ve eski detay modal kodlari temizlendi; modern haber karti ve mevcut detay dialogu korunur.

### Haber Detay Karti

- Detay ekrani alttan acilan bottom sheet yerine tekrar ortada acilan dialog mantigina alindi.
- Yeni detay tasariminda kaynak etiketi, kapatma butonu, baslik hiyerarsisi ve okunabilir metin duzeni korundu.
- Detay dialogu enine buyutuldu.

### Girissiz Kullanım

- Auth ekranindan girissiz devam edildiginde ana sayfa acilir.
- Kullanici yoksa partner alani bos kalmak yerine ornek detoks karti gosterir.
- Ana sayfadaki detoks, partner ve durum kartlari ortak kart kabugu, sakin golge, mini ikon alanlari ve kompakt durum hiyerarsisiyle yenilendi.
- Partner durumlari hizli his secenekleriyle gelistirildi; kullanici ayrica partner kartinda gorunecek 80 karakterlik mini not birakabilir.
- Partnerine cizim gonderme ozelliginin ilk surumu eklendi; cizimler Firestore'da normalize stroke listesi olarak tutulur ve partner kartinda onizleme olarak gosterilir.
- Durum guncelleme penceresine `Paylastiklarin` bolumu eklendi; mini not ve cizim varsa burada kart olarak gorunur ve kendi silme butonlariyla temizlenir.
- Paylasilan mini not ve cizim silme islemleri onay dialoguna baglandi.
- Hazir durumlar iki satir grid yerine yatay kaydirilabilir tek satir chip yapisina tasindi.
- Hazir durum emojileri Material ikon tabanli durum anahtarlarina tasindi; eski emoji kayitlari geriye uyumlu gosterilir.
- Durum/not/cizim islemleri tema uyumlu basari-hata mesajlari gosterir.
- Partner kartinda not ve cizim ayni anda varsa kucuk kartta `Not + cizim` etiketiyle cizim onizlemesi gosterilir.
- Partner karti cizim odakli hale getirildi; partnerin son cizimi ana alanda daha buyuk gorunur, durum satiri daha kompakt tutulur.
- Partner not paylastiysa kart basliginin yaninda kucuk bir bildirim noktasi gosterilir.
- Partner kartina basilinca partnerin son 3 durum/not/cizim paylasimi detay panelinde listelenir.

### Ayarlar Ekrani

- Profil/uyelik bolumu modern bir karta alindi.
- Eslesme bolumu kartlastirildi.
- Gorunum ve Bildirimler bolumleri uygulama tasarim diline uygun kartlara tasindi.
- Toggle satirlari daha kompakt ve dolgulu hale getirildi.
- Girissiz kullanimda profil karti `Giris yapilmadi`, eslesme karti ise giris gerektiren bilgilendirici durum gosterir.
- Kucuk ekranlarda tasma riskini azaltmak icin eslesme ve toggle satirlarinin bosluklari sikilastirildi.
- Eslesme karti ikonlu kod paneli, cizgili `VEYA` ayraci ve ikonlu kod giris alaniyla modernlestirildi.
- Eslesme kartinda kalp ikonu kaldirildi; kullanici eslesmisse partnerin mevcut durumu ve partner icin takma ad kaydetme alani gosterilir.
- Eslesme karti minimal kontrol paneli yapisina tasindi; eslesme yokken kod olusturma/girme iki kompakt satirda gosterilir.
- Eslesme varsa kartta partner durumu, takma ad alani ve onay dialoglu `Eslesmeyi bitir` aksiyonu bulunur.
- Ayarlar ekraninda artik kullanilmayan eski eslesme paneli ve yardimci divider kodlari temizlendi; aktif eslesme davranisi korunur.
- Gorunum kartindaki iki ayri tema switch'i kaldirildi; ikonlu tek segment kontrolu ile `Acik`/`Koyu` secimi yapilir.
- Tema segmentinde secili alan gecisi `AnimatedPositioned` ile daha temiz hale getirildi; kart ici hizalama ve bosluklar duzenlendi.
- Tema segmentindeki ikonlar kaldirildi; `Acik`/`Koyu` metinleri ortalandi ve gecis animasyonu yumusatildi.
- Profil karti daha kompakt hale getirildi; uyelik durumu pill olarak gosterilir, detay ve giris/cikis aksiyonlari sade satirlar halindedir.
- Profil kartindaki giris/cikis aksiyonu alt satirda kart ortasina hizalandi.
- Bildirim karti aciklamali uc kompakt satirla yeniden duzenlendi; aktif sayisi pill'i gereksiz tekrar oldugu icin kaldirildi.

### Uygulama Mesajlari

- Hata, basari ve bilgi mesajlari icin `AppFeedback` yardimci sinifi eklendi.
- Auth ve Ayarlar ekranlarindaki snackbar mesajlari uygulamanin acik/koyu tema diline uygun kart gorunumune tasindi.
- Eslesmeyi bitirme onay dialogu tema uyumlu, yuvarlak koseli ve daha sakin bir tasarima guncellendi.
- Global `SnackBarThemeData` eklendi; ileride duz `SnackBar` kullanilsa bile genel tema dili korunur.

## Onemli Classlar

### `MyApp` - `lib/main.dart`

Uygulamanin MaterialApp, tema ve genel baslangic yapisini kurar. `themeNotifier` ile acik/koyu tema degisimini dinler.

### `SplashScreen` - `lib/screens/splash_screen.dart`

Uygulama acilis ekranidir. Firebase oturumu varsa `HomeScreen`, yoksa `AuthScreen` acar.

### `AuthScreen` - `lib/screens/auth_screen.dart`

Giris/kayit ekranidir. E-posta/sifre, Google girisi, sifre sifirlama ve gecici girissiz devam akislarini icerir.

### `HomeScreen` - `lib/screens/home_screen.dart`

Ana haber akisini, finans kartini, partner/detoks alanini ve haber detay dialogunu yonetir.

### `SettingsScreen` - `lib/screens/settings_screen.dart`

Profil, tema, bildirim tercihleri ve partner eslesme ayarlarini yonetir.

### `PartnerWidget` - `lib/widgets/partner_widget.dart`

Detoks karti, partner durumu ve kullanicinin kendi durum kartlarini gosterir. Girissiz kullanimda ornek detoks karti verir.

### `WeatherWidget` - `lib/widgets/weather_widget.dart`

Konum izni ve OpenWeather API ile hava durumu gostermek icin hazirlanmis widgettir. Su an ana ekranda aktif kullanilmiyor.

### `AppFeedback` - `lib/widgets/app_feedback.dart`

Uygulama genelindeki hata, basari ve bilgi snackbar mesajlarini tema uyumlu tek bir kart stilinde gosterir.

## Onemli Fonksiyonlar

### Auth

- `_signInWithGoogle`: Google hesabi ile Firebase Auth girisi yapar.
- `_submitAuthForm`: E-posta/sifre ile giris veya kayit islemini yapar.
- `_resetPassword`: Girilen e-posta adresine sifre sifirlama baglantisi gonderir.
- `_buildModeSwitch`: Giris/Kayit arasindaki kayan segment kontrolunu olusturur.
- `_buildSkipButton`: Gelistirme icin giris yapmadan ana sayfaya gecis saglar.

### Home

- `_saveDeviceToken`: FCM token bilgisini kullanicinin Firestore dokumanina yazar.
- `_buildLiveWidgets`: Finans ve partner/detoks kartlarini yan yana gosterir.
- `_buildNewsFeed`: Firestore `news` koleksiyonunu dinleyip haber listesini olusturur.
- `_buildModernNewsCard`: Admin panelinden gelen mevcut haber alanlarini modern kart tasariminda gosterir.
- `_formatCreatedAt`: `createdAt` alanini kart uzerinde okunabilir kisa tarih formatina cevirir.
- `_showModernDetailModal`: Haber detayini ortada acilan modern dialog olarak gosterir.

### Settings

- `_loadSettings`: Bildirim tercihlerini cihazdan okur.
- `_updateTheme`: Tema tercihini kaydeder ve uygulamaya uygular.
- `_generatePairCode`: Kullanici icin eslesme kodu olusturur.
- `_enterPairCode`: Girilen kodla partner eslesmesi yapar.
- `_confirmUnpair`: Eslesmeyi bitirmeden once tema uyumlu onay dialogu acar.
- `_unpairPartner`: Iki kullanici arasindaki eslesme verilerini Firestore uzerinden temizler.
- `_buildProfileCard`: Profil ve uyelik bilgilerini uygulama kart dilinde gosterir.
- `_buildSettingsCard`: Ayarlar alt bolumleri icin ortak kart kabugu saglar.
- `_buildPairingSection`: Eslesme kodu olusturma/girme arayuzunu gosterir.
- `_buildNotificationOption`: Bildirim tercihlerini aciklamali, tema uyumlu kompakt satirlar olarak gosterir.

### Feedback

- `AppFeedback.show`: Mesaj metnini `info`, `success` veya `error` tipine gore ikonlu, yuvarlak koseli ve temaya uyumlu snackbar olarak gosterir.

### Partner

- `_buildDetoxPage`: Haber sayisina gore kazanilan dakika ve ozet sayisini gosterir.
- `_buildConnectPage`: Partner yoksa eslesme ayarlarina yonlendirir.
- `_buildPartnerPage`: Eslesilen partnerin durumunu gosterir.
- `_buildMyStatusPage`: Kullanicinin kendi durumunu gosterir.
- `_buildCardShell`: Ana sayfadaki detoks ve partner kartlari icin ortak kart kabugunu olusturur.
- `_buildHeaderRow`: Kart basligi, sayfa noktasi ve mini ikon alanini uretir.
- `_buildStatusBubble`: Partner veya kullanici durum ikonunu kompakt yuvarlak alanda gosterir.
- `_statusIconData`: Firestore'daki durum ikon anahtarlarini Material ikonlara cevirir.
- `_buildStatusMark`: Yeni ikon anahtarlarini ikon, eski emoji kayitlarini metin olarak gosterir.
- `_showStatusPicker`: Durum secme/guncelleme bottom sheet'ini acar.
- `_updateStatus`: Kullanicinin `statusIcon`, `statusText` ve `lastUpdated` alanlarini Firestore'a yazar.
- `_sendPartnerNote`: Partner kartinda gorunecek `partnerNote` bilgisini Firestore'a yazar ve partner bildirimini tetikler.
- `_deletePartnerNote`: Gonderilen mini not alanlarini Firestore dokumanindan temizler.
- `_showSketchComposer`: Basit cizim alanini acar.
- `_sendPartnerSketch`: Partner kartinda gorunecek cizim stroke verisini Firestore'a yazar.
- `_deletePartnerSketch`: Gonderilen cizim verisini Firestore dokumanindan temizler.
- _savePartnerShare: Durum, mini not ve cizim paylasimlarini partnerShares listesine yazar ve listeyi son 3 kayitla sinirlar.
- _deletePartnerShareType: Mini not veya cizim silindiginde ilgili tipteki gecmis paylasim kayitlarini temizler.
- _showPartnerSharesSheet: Partner kartina basilinca partnerin son paylasimlarini detay panelinde gosterir.
- _partnerSharesFromData: Yeni partnerShares listesini okur; eski kullanicilar icin mevcut son durum/not/cizim alanlarindan fallback uretir.
- `_notifyPartner`: Partnerin cihaz tokenina bildirim gonderir.

## Veri Modeli Notlari

Haber kartlarini modernlestirirken admin paneli veri yapisi bozulmadi. Mevcut alanlar korunur:

```text
news/{docId}
- title
- summary
- detail
- source
- createdAt
```

`createdAt` yoksa tarih gosterilmez. `detail` yoksa detay dialogunda `summary` kullanilir.

Partner durumlari icin `users/{uid}` dokumaninda kullanilan alanlar:

```text
users/{uid}
- statusIcon
- statusText
- lastUpdated
- partnerNote
- partnerNoteUpdatedAt
- partnerSketch
- partnerShares
  - id
  - type: status | note | sketch
  - text
  - icon
  - strokes
  - createdAt
```

`partnerNote`, notu yazan kullanicinin dokumaninda tutulur; eslesilen kisi partner kartinda bu notu okur.
`partnerSketch`, cizimi yapan kullanicinin dokumaninda tutulur; eslesilen kisi partner kartinda kucuk onizleme olarak gorur.

partnerShares, durum/not/cizim paylasimlarinin son 3 kaydini tutar; ana kart son cizimi, detay paneli ise bu sinirli gecmisi kullanir.
## Sonraki Isler

- Eski kullanilmayan haber karti fonksiyonunu temizlemek.
- Ayarlar ekranini cihazda gorsel olarak test edip spacing/overflow duzeltmeleri yapmak.
- Finans ve detoks kartlarini haber kartlariyla ayni kaliteye yaklastirmak.
- FCM server key ve OpenWeather API key gibi client icindeki gizli bilgileri backend tarafina tasimak.
- Genel lint uyarilarini kademeli temizlemek.
