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

- Haber akisi RSS/admin onay akisina hazirlik icin yayin filtresi kullanir: `published: false`, `status: draft` ve `status: rejected` mobilde gosterilmez.
- Eski manuel haberlerde `published` veya `status` yoksa haber gorunmeye devam eder; mevcut admin veri girisi bozulmaz.
- Haber kartlari `category`, `sourceUrl` ve `publishedAt` alanlarini destekler; gorsel alan kullanilmaz.
- Haber detay kartinda sourceUrl varsa Kaynagi ac satiri uygulama icindeki WebView haber okuma ekranini acar.
- Admin panelde yeni manuel haberler artik `draft_news` yerine `news` koleksiyonuna `status: draft` ve `published: false` ile kaydedilir.
- Admin panel yayinlama aksiyonu ayni `news` dokumanini `status: published`, `published: true` ve `publishedAt` ile canliya alir.
- Eski `draft_news` kayitlari admin panelde gorunmeye devam eder; yayinlaninca `news` koleksiyonuna tasinir ve eski taslak silinir.
- Admin panelde RSS kaynak yonetimi icin `rss_sources` koleksiyonu eklendi; kaynak cekme islemi backend/Cloud Function tarafina baglanacak.
- Cloud Function RSS importer iskeleti `ozet-admin-panel/functions` altina eklendi.
- `importRssNow` callable function admin paneldeki `Simdi RSS Cek` butonundan calisir; oturum acmis Firebase kullanicisi gerekir. Cloud Run preflight istegi icin `invoker: public` ayarlidir, guvenlik kontrolu function icindeki `request.auth` ile yapilir.
- `importRssScheduled` aktif RSS kaynaklarini her 5 saatte bir cekmek icin zamanlanmis function olarak tanimlandi.
- RSS importer kaynak basina en fazla 10 haber alir, ayni kaynak URL/guid icin deterministik `rss_` dokuman id'si kullanarak tekrar eklemeyi engeller.
- RSS'den gelen haberler `news` koleksiyonuna `status: draft`, `published: false` olarak yazilir; mobil uygulamada admin yayinlayana kadar gorunmez.
- RSS kaynagi normal HTML sayfasiysa importer sayfa icindeki RSS/Atom alternate linklerini arar ve calisan feed adresini resolvedFeedUrl olarak kaydeder.
- RSS cekme sonucu artik errors listesiyle ilk hata detayini admin panele dondurur; haber bulunamazsa sessiz 0 yeni yerine aciklama gosterilir.
- RSS taslaklari admin panelde RSS etiketiyle manuel haberlerden ayrilir; kisa ozet ve Kaynagi ac linkiyle hizli kontrol edilebilir.
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

### `NewsWebViewScreen` - `lib/screens/news_webview_screen.dart`

RSS/manual haber kaynak linklerini uygulama icinde WebView ile acar; ustte haber basligi, site adresi, yenile aksiyonu ve yukleme ilerleme cizgisi gosterir.

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
- `_buildNewsFeed`: Firestore `news` koleksiyonunu dinleyip yalnizca mobilde gorunebilir haber listesini olusturur.
- `_buildModernNewsCard`: Admin panelinden gelen mevcut haber alanlarini modern kart tasariminda gosterir.
- `_isVisibleNews`: RSS taslaklarini ve reddedilen haberleri mobil akistan filtreler.
- `_textField`: Firestore metin alanlarini bosluklardan arindirarak guvenli okur.
- `_buildNewsMetaChip`: Kategori ve kaynak bilgisini haber kartinda kompakt etiket olarak gosterir.
- `_formatCreatedAt`: `createdAt` veya `publishedAt` alanini kart uzerinde okunabilir kisa tarih formatina cevirir.
- `_showModernDetailModal`: Haber detayini ortada acilan modern dialog olarak gosterir.
- `_openSourceUrl`: Haber kaynaginin URL bilgisini dogrular, detay dialogunu kapatir ve `NewsWebViewScreen` ekranini uygulama icinde acar.

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

### Admin Panel

- `loadDraftNews`: `news` icindeki `draft/reviewed` haberleri ve eski `draft_news` taslaklarini onay listesinde gosterir.
- `publishDraft`: Taslagi ayni dokuman uzerinden yayinlar; eski `draft_news` kayitlarini `news` koleksiyonuna tasir.
- `unpublishNews`: Canli haberi silmek yerine `status: rejected`, `published: false` yaparak mobil akistan kaldirir.
- `loadRssSources`: RSS kaynaklarini `rss_sources` koleksiyonundan listeler.
- `isRssNews`: Haber kaydinin RSS importer tarafindan olusturulup olusturulmadigini `rssSource` veya `rssItemId` alanlarindan anlar.
- `escapeHtml`: RSS gibi dis kaynaklardan gelen metinleri admin panel kartlarina guvenli basmak icin HTML karakterlerini kacar.
- RSS kaynak formu: `name`, `url`, `defaultCategory`, `active`, `lastFetchedAt`, `lastError` alanlarini yonetir.
### Cloud Functions

- `importActiveRssSources`: Aktif `rss_sources` kayitlarini okur, RSS/Atom feedlerini ceker ve yeni haberleri `news` koleksiyonuna taslak olarak yazar.
- `importSource`: Tek kaynak icin haberleri normalize eder, tekrar eklemeyi `rss_` dokuman id'siyle engeller ve kaynak uzerinde `lastFetchedAt`/`lastError` alanlarini gunceller.
- loadFeed: Girilen URL dogrudan RSS/Atom degilse HTML icinden feed linki kesfetmeye calisir.
- discoverFeedUrls: HTML alternate linkleri ve feed benzeri anchor URLlerinden RSS/Atom adaylarini cikarir.
- parseFeed, parseRssItem, parseAtomEntry: Ek paket kullanmadan RSS/Atom XML iceriginden temel haber alanlarini okur.
- `stableId`: Kaynak ve haber URL/guid bilgisinden tekrar uretilebilir Firestore dokuman id'si olusturur.
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
- sourceUrl
- rssSource
- category
- tags
- published
- status: draft | reviewed | published | rejected
- createdAt
- publishedAt
- originalTitle
- originalText
- aiGenerated
```

`createdAt` veya `publishedAt` yoksa tarih gosterilmez. `detail` yoksa detay dialogunda `summary` kullanilir.
Mobil akista gorunurluk kurali: `published: true` veya `status: published` gorunur; `published: false`, `status: draft` ve `status: rejected` gizlenir. Eski manuel kayitlarda bu alanlar yoksa haber gorunur kalir.

RSS kaynaklari icin kullanilan alanlar:

```text
rss_sources/{docId}
- name
- url
- defaultCategory
- active
- createdAt
- lastFetchedAt
- lastError
- resolvedFeedUrl
```

`rss_sources` su an sadece kaynak kaydi tutar. RSS cekme islemi tarayici icinden yapilmaz; CORS ve guvenlik sebepleriyle backend/Cloud Function tarafinda calismalidir.
Functions deploy notu: `ozet-admin-panel/functions` altinda `npm install` calistirildiktan sonra Firebase deploy yapilmalidir. Functions runtime Node 22 olarak ayarlandi; `firebase-functions@7.2.5` ve `firebase-admin@13.6.0` birlikte kullanilir.
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
## AI Ozetleme Akisi

- Admin panelde taslak haber kartlarina `AI Ozetle` / `AI Yenile` aksiyonu eklendi.
- Aksiyon sadece yeni `news` koleksiyonundaki taslaklarda calisir; eski `draft_news` kayitlari once mevcut yayinlama akisiyla `news` tarafina tasinmalidir.
- AI islemi tarayici tarafindan direkt Gemini API'ye gitmez. Admin panel `summarizeNewsWithAi` callable function'ini cagirir.
- `summarizeNewsWithAi`, Firebase Auth oturumunu ve `admins/{email}` dokumanini kontrol eder, sonra secilen haberin `title`, `summary`, `detail`, `tags`, `aiGenerated`, `aiModel`, `aiSummarizedAt` alanlarini gunceller.
- `GEMINI_API_KEY` client koduna yazilmaz; Firebase Functions secret olarak tanimlanir.
- Deploy oncesi gerekli komut: `firebase functions:secrets:set GEMINI_API_KEY`.


### Admin Taslak Kontrolu

- Taslak haber kartlarinda `Ozeti Gor` kontrolu bulunur; bu kontrol kisa ozet ve detay metnini kart icinde acarak AI sonucunu yayina almadan once kontrol etmeyi saglar.
- Onay bekleyen taslaklarda coklu secim vardir. Secilen taslaklar topluca yayinlanabilir veya onaydan sonra topluca silinebilir.
### AI Tarafinda Kullanilan Fonksiyonlar

- `assertAdmin`: Callable function cagrilarinda kullanicinin admin yetkisini Firestore `admins/{email}` dokumanindan dogrular.
- `buildAiSourceText`: Haber dokumanindaki baslik/ozet/detay/orijinal metni ve varsa `sourceUrl` sayfasindan alinan metni AI icin tek kaynak metne toplar.
- `cleanHtmlArticleText`: Haber sayfasindan gelen HTML icerigi temizleyip okunabilir metne cevirir.
- `summarizeWithGemini`: Gemini generateContent API'ye JSON modunda istek gonderir; baslik, kisa ozet, detay ve tag alanlarini alir.
- `extractGeminiResponseText`: Gemini generateContent yanitindaki aday metin parcalarini tek metne donusturur; bos yanitta finish/block sebebini hata mesajina ekler.
- `summarizeDraftWithAi`: Admin panel taslak kartindaki AI butonunu Cloud Function'a baglar ve islem bitince taslak listesini yeniler.
- `draftSelectionKey`, `setDraftSelection`, `syncSelectedDraftsWithVisible`: Admin panelde taslak kartlarinin coklu secim durumunu yonetir.
- `publishSelectedDrafts`: Secilen taslaklari tek batch ile canliya alir; eski `draft_news` kayitlarini `news` koleksiyonuna tasir.
- `deleteSelectedDrafts`: Secilen taslaklari onaydan sonra ilgili koleksiyonlardan topluca siler.
## Admin Panel Responsive Yonetim Kabugu

- Admin panel dar ve ortalanmis tek kart yapisindan masaustu alanini kullanan tam genislikte yonetim kabuguna tasindi.
- Tum yonetim bolumleri yapiskan ust barda sekme olarak bulunur; mobilde sekmeler yatay kaydirilarak kullanilir.
- Genel bakis alaninda canli haber, taslak, AI ozetli haber, aktif RSS, bugun yayinlanan haber ve RSS hata sayilari gosterilir.
- Istatistikler yeni Firestore sorgulari acmaz; taslak, canli haber ve RSS listelerini yukleyen mevcut sorgularin sonuclarindan hesaplanir.
- Haber listeleri, toplu islem cubuklari ve formlar 1180px, 860px, 620px ve 390px kirilimlarinda yeniden duzenlenir.
- Canli haberler secilebilir; secilenler topluca yayindan kaldirilabilir veya geri alinamaz onayindan sonra kalici silinebilir.
- Yayindan kaldirma published: false, status: rejected alanlarini yazar; kalici silme secilen news dokumanlarini Firestore batch ile siler.

### Yeni Admin Fonksiyonlari

- refreshAdminData: Tum panel verilerini birlikte yeniler ve son yenileme saatini gosterir.
- setSidebarOpen: Mobil yan menuyu ve arka plan katmanini yonetir.
- setLiveSelection, syncSelectedLiveNews, updateLiveBulkToolbar: Canli haber secimlerini ve toplu islem butonlarini yonetir.
- unpublishSelectedLiveNews: Secilen canli haberleri tek batch ile yayindan kaldirir.
- deleteSelectedLiveNews: Onaydan sonra secilen canli haberleri tek batch ile kalici siler.
## Sonraki Isler

- Eski kullanilmayan haber karti fonksiyonunu temizlemek.
- Ayarlar ekranini cihazda gorsel olarak test edip spacing/overflow duzeltmeleri yapmak.
- Finans ve detoks kartlarini haber kartlariyla ayni kaliteye yaklastirmak.
- FCM server key ve OpenWeather API key gibi client icindeki gizli bilgileri backend tarafina tasimak.
- Genel lint uyarilarini kademeli temizlemek.
