# Ozet App Gelistirme Notlari

Bu dokuman, uygulamada yaptigimiz tasarim ve davranis degisikliklerini takip etmek icin tutulur. Yeni bir ozellik, tasarim karari veya onemli refactor yapildiginda burasi guncellenecek.

## Uygulama Ozeti

Ozet App, Firebase tabanli bir Flutter haber/ozet uygulamasidir.

- Kullanici Firebase Auth ile e-posta/sifre veya Google hesabi ile giris yapar.
- Splash ekrani mevcut oturuma gore kullaniciyi ana sayfaya veya auth ekranina yonlendirir.
- Ana sayfa Firestore `news` koleksiyonundan haberleri okur; finans kartinin yerinde cihazda saklanan gunluk puan kartini gosterir.
- Haberler admin panelinden manuel eklenen alanlarla calisir: `title`, `summary`, `detail`, `source`, `createdAt`.
- Partner/eslesme ozelligi Firestore `users` dokumanlari uzerinden calisir.
- Tema secimi ve bildirim tercihleri `SharedPreferences` ile cihazda saklanir.

## Yapilan Degisiklikler

### Gunun Puani

- Finans karti kaldirildi; solda Partner/Eslesme ile Durumum, sagda Gunun Puani ile Detoks arasinda yatay gecis yapan iki tam boy kart alani kuruldu.
- Kullanici ruh hali, enerji, ilerleme, kendine zaman ve huzur sorularini 1-10 arasinda puanlar.
- Bes sorunun esit agirlikli ortalamasi gunun puani olarak hesaplanir.
- Kullanici puanlamaya ek olarak en fazla 200 karakterlik istege bagli gun notu yazabilir.
- Kayit tamamlandiginda ana ekrandaki kart tarih, ortalama, kisa gun karsiligi ve varsa not onizlemesini gosterir.
- Ana ekrandaki Gunun Puani kartinin puan, sayfa gostergesi ve gecmis aksiyonu acik temada siyah, koyu temada kirik beyaz vurgu kullanir; Detoks renkleri degistirilmedi.
- `PartnerWidget` solda Partner/Eslesme ile Durumum sayfalarini, `DailyCardsWidget` sagda Gunun Puani ile Detoks sayfalarini ayni yatay kaydirma mekanizmasiyla gosterir.
- Bes soru uzun bir form yerine tek soruluk odakli adimlar halinde gosterilir; ilerleme 1/5 cubuguyla izlenir.
- Her soruda dokunma ve suruklemeye aninda tepki veren 10 kademeli ozel puan bari, secili puan ve kisa puan karsiligi bulunur; soru gecisleri yumusak kayma/solma animasyonu kullanir.
- Son adimda gunun ortalamasi ve kisa sonucu gosterilir; kullanici istege bagli notunu burada ekler.
- Alt gezinmede geri aksiyonu sabit ikon butonu olarak kalir; soru adimindaki ileri butonu 132x48 olcusunde saga hizalanir, son kaydetme butonu metne uygun genisler. Vurgular acik temada siyah, koyu temada kirik beyazdir.
- Ayni gunun kaydi karta yeniden basilarak duzenlenebilir.
- Kayitlar kullanici/guest anahtarina gore `SharedPreferences` icinde JSON olarak tutulur; ileride haftalik veriler hesaplanabilir.
- Ana karttaki gecmis ikonu kayitlari ay bazinda gruplanmis, yeniden eskiye sirali arsiv ekraninda acar.
- Gecmis gun kartina basildiginda bes soru puani, gun sonucu ve tam not ayri detay ekraninda gosterilir; istatistik, silme ve gecmis gunu duzenleme eklenmedi.
- Her kayit soru seti surumunu tasir; sorular degistiginde eski gunlerin hangi duzenle puanlandigi korunur.
- Haftalik istatistik arayuzu henuz eklenmedi. Gosterilecek parametreler urun karari verildikten sonra eklenecek.

### Auth Ekrani

- Giriş/Kayit ekrani modernlestirildi.
- Giriş/Kayit gecisi tek parca kayan segment bara donusturuldu.
- Google girisi logo yerine buton olarak tasarlandi.
- Sifre goster/gizle ozelligi eklendi.
- Sifremi unuttum Firebase password reset akisina baglandi.
- Gelistirme icin gecici `Şimdilik giriş yapmadan devam et` butonu eklendi.

### Ana Sayfa Haber Kartlari

- Haber kartlari modern kart tasarimina tasindi.
- Kategori ve kaynak etiketleri seffaf zemin, ince notr cerceve ve tema uyumlu yazi rengiyle gosterilir.
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
- Haber detayindaki kaynak etiketi ve Kaynagi ac alani da seffaf, ince cerceveli notr duzeni kullanir.
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
- Durum guncelleme panelindeki ozel durum ve not aksiyonlari siyah/kirik beyaz ana butonlara, girisler, hizli durumlar ve paylasim kartlari 8px koseli notr yuzeylere tasindi.
- Durum guncelleme paneli iOS/Liquid Glass dilinde yeniden kuruldu; tek blur katmanli yari saydam kabuk, Inter tipografi, cam durum kapsulleri, alan ici dairesel gonderme aksiyonlari ve cam cizim satiri kullanildi.
- Cizim gonderme ekrani ayni iOS/Liquid Glass diline tasindi; cam panel, Inter baslik, daha okunakli tuval, secim animasyonlu renk paleti, dairesel geri al/temizle kontrolleri ve durum duyarlı gonderme butonu eklendi.
- Durum panelindeki aktif cizim, mini not kartindan ayrilan ozel bir karta tasindi; baslik/silme satiri ustte, kare orani korunan 150px onizleme alani altta gosterilerek cizimin ezilmesi engellendi.
- Durum panelinden cizim ekranina gecis rota sonucuyla siralandi; eski bottom sheet tamamen sokulmeden controller temizlenmesi veya yeni sheet acilmasi engellenerek Flutter `_dependents.isEmpty` assertion hatasi giderildi.
- Partner kartinda not ve cizim ayni anda varsa kucuk kartta `Not + cizim` etiketiyle cizim onizlemesi gosterilir.
- Partner karti cizim odakli hale getirildi; partnerin son cizimi ana alanda daha buyuk gorunur, durum satiri daha kompakt tutulur.
- Ana sayfadaki Partner/Eslesme ve Durumum kartlarinin renkli UI vurgulari acik temada siyah, koyu temada kirik beyaz olarak guncellendi; kullanicinin cizim renkleri korundu.
- Ana partner karti tek blur katmanli Liquid Glass kabuga tasindi; gri dolgu yuzeyleri kaldirildi, cizim beyaz/seffaf kagit caminda gosterildi, durum satiri kutusuz hale getirildi ve kalp ikonu notr partner ikonuyla degistirildi.
- Partner karti ve yatay cizim onizlemeleri, kart boyutunu degistirmeden cizgi sinirlarini hesaplayan oran korumali akilli sigdirma kullanir; bos alanlar azaltildigi icin cizim basik gorunmez.
- Partner kartinin ana yuzeyi, saydam renk karisimi yerine ana ekrandan gelen `kartRengi` degerini kullanir; boylece Gunun Puani kartiyla acik ve koyu temada ayni renkte gorunur.
- Partner not paylastiysa kart basliginin yaninda kucuk bir bildirim noktasi gosterilir.
- Partner kartina basilinca partnerin son 3 durum/not/cizim paylasimi detay panelinde listelenir.

### Ayarlar Ekrani

- Ayarlar ekrani bastan sona Inter tipografili, 640px genislik sinirli ve kaydirmada tek blur katmani kullanan responsive bir yapiya tasindi.
- Eski mavi vurgu renkleri kaldirildi; kart, kontrol, metin, kenarlik ve switch renkleri `_SettingsPalette` uzerinden siyah, beyaz ve notr grilerle yonetilir.
- Profil, eslesme, gorunum ve bildirim bolumleri ortak yuzey/golge diline alindi; ic ice gereksiz gri kartlar kaldirildi.
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
- Eslesme karti baglanti paneline donusturuldu; baslikta `Bekliyor`/`Isleniyor`/`Bagli` rozeti, durumlar arasinda 240ms gecis ve yukleme sirasinda acik durum satiri kullanilir.
- Eslesme yokken tek kullanimlik kod buyuk odak alaninda gosterilir; kod olusturma, kopyalama ve yenileme aksiyonlari ile partner kodu girisi ayni panelde tutulur.
- Eslesme varken partner ozeti ve durumu ust bantta gosterilir; takma ad satirinin tamamina veya kalem ikonuna basildiginda klavyeye uyumlu Liquid Glass alt panel acilir.
- Takma ad paneli partner kartinin canli onizlemesini, 24 karakter sinirini, kaydetme durumunu ve mevcut takma adi kaldirma aksiyonunu birlikte sunar.
- Ayarlar ekraninda artik kullanilmayan eski eslesme paneli ve yardimci divider kodlari temizlendi; aktif eslesme davranisi korunur.
- Gorunum kartindaki iki ayri tema switch'i kaldirildi; ikonlu tek segment kontrolu ile `Acik`/`Koyu` secimi yapilir.
- Tema segmentinde secili alan gecisi `AnimatedPositioned` ile daha temiz hale getirildi; kart ici hizalama ve bosluklar duzenlendi.
- Tema segmentindeki ikonlar kaldirildi; `Acik`/`Koyu` metinleri ortalandi ve gecis animasyonu yumusatildi.
- Profil karti daha kompakt hale getirildi; uyelik durumu pill olarak gosterilir, detay ve giris/cikis aksiyonlari sade satirlar halindedir.
- `Cikis Yap` profil kartindan kaldirildi; Ayarlar sayfasinin en altina tam genislikte, dolgulu ve cerceveli belirgin bir buton olarak tasindi.
- Bildirim karti aciklamali uc kompakt satirla yeniden duzenlendi; aktif sayisi pill'i gereksiz tekrar oldugu icin kaldirildi.
- Ayarlar sayfasindaki ana kartlar arasindaki dikey bosluk 16px'ten 8px'e indirildi; kartlarin ic bosluklari korunur.

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

Ana haber akisini, Gunun Puani kartini, partner/detoks alanini ve haber detay dialogunu yonetir.

### `DailyScoreEntry` - `lib/models/daily_score_entry.dart`

Bes soru puanini, gun notunu, tarih anahtarini, gunluk ortalamayi ve kisa sonuc etiketini tasir.

### `DailyScoreStorage` - `lib/services/daily_score_storage.dart`

Gunluk puan kayitlarini oturum acmis kullanici veya misafir icin ayri cihaz anahtarlarinda JSON olarak saklar; tum gecerli kayitlari bozuk verileri atlayarak yeniden eskiye sirali okuyabilir.

### `DailyScoreScreen` - `lib/screens/daily_score_screen.dart`

Bes soruyu tek tek sunan ilerlemeli akisi, dogrudan dokunma/surukleme algilayan 10 kademeli puan barini, sonuc/not adimini ve gun karti olusturma/guncelleme islemini yonetir.

### `DailyScoreHistoryScreen` - `lib/screens/daily_score_history_screen.dart`

Gunluk kayitlari ay basliklari altinda listeler; bos, yukleniyor ve hata durumlarini yonetir ve secilen kaydi detay sayfasina acar.

### `DailyScoreDetailScreen` - `lib/screens/daily_score_history_screen.dart`

Tek bir gunun tarihini, ortalamasini, sonuc etiketini, bes soru puanini ve tam notunu salt okunur olarak gosterir.

### `DailyCardsWidget` - `lib/widgets/daily_cards_widget.dart`

Ana sayfanin sag kartinda Gunun Puani ve Detoks sayfalarini iki nokta gostergeli yatay `PageView` ile gosterir; puanlama ve gecmis ekranlarini ayri aksiyonlarla acar, yayindaki haberlerden detoks suresini hesaplar.
### `SettingsScreen` - `lib/screens/settings_screen.dart`

Profil, tema, bildirim tercihleri ve partner eslesme ayarlarini; responsive genislik, sabit cam ust bar ve ortak monokrom kart sistemiyle yonetir.

### `_SettingsPalette` - `lib/screens/settings_screen.dart`

Ayarlar ekraninin acik/koyu tema yuzeylerini, metinlerini, kenarliklarini, vurgu ve tehlike renklerini tek noktadan uretir.

### `_NicknameEditorSheet` - `lib/screens/settings_screen.dart`

Partner takma adini canli kart onizlemesiyle duzenleyen, klavye bosluguna uyum saglayan ve kaydetme/kaldirma durumlarini yoneten Liquid Glass alt paneldir.

### `PartnerWidget` - `lib/widgets/partner_widget.dart`

Partnerin paylasim karti ile kullanicinin kendi Durumum kartini yatay gecisle gosterir. Girissiz kullanimda eslesme/giris yonlendirmesi verir.

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
- `_loadTodayScore`: Bugunun daha once kaydedilmis puanini cihazdan yukler.
- `_openDailyScore`: Puanlama ekranini acar, donen gun kaydini saklar ve ana karti yeniler.
- `_openDailyScoreHistory`: Aylik gecmis kayit listesini uygulama icinde acar.
- `_buildLiveWidgets`: Solda `PartnerWidget`, sagda Gunun Puani/Detoks arasinda kayan `DailyCardsWidget` kartini gosterir.
- `_buildNewsFeed`: Firestore `news` koleksiyonunu dinleyip yalnizca mobilde gorunebilir haber listesini olusturur.
- `_buildModernNewsCard`: Admin panelinden gelen mevcut haber alanlarini modern kart tasariminda gosterir.
- `_isVisibleNews`: RSS taslaklarini ve reddedilen haberleri mobil akistan filtreler.
- `_textField`: Firestore metin alanlarini bosluklardan arindirarak guvenli okur.
- `_buildNewsMetaChip`: Kategori ve kaynak bilgisini seffaf zeminli, ince cerceveli tema uyumlu kompakt etiket olarak gosterir.
- `_formatCreatedAt`: `createdAt` veya `publishedAt` alanini kart uzerinde okunabilir kisa tarih formatina cevirir.
- `_showModernDetailModal`: Haber detayini ortada acilan modern dialog olarak gosterir.
- `_openSourceUrl`: Haber kaynaginin URL bilgisini dogrular, detay dialogunu kapatir ve `NewsWebViewScreen` ekranini uygulama icinde acar.

### Daily Score

- `DailyScoreStorage.getAll`: Gecerli kayitlari ayristirir, bozuk olanlari atlar ve tarih azalan sirada dondurur.
- `_reload`: Gecmis ekraninin yerel kayit listesini yeniden yukler.
- `_openEntry`: Secilen gun kaydini `DailyScoreDetailScreen` icinde acar.
- `_groupByMonth`: Sirali gun kayitlarini ay/yil basliklari altinda gruplar.

### Settings

- `_loadSettings`: Bildirim tercihlerini cihazdan okur.
- `_saveNotificationSetting`: Secilen bildirim tercihini ekranda aninda gunceller ve `SharedPreferences` icine kaydeder.
- `_updateTheme`: Tema tercihini kaydeder ve uygulamaya uygular.
- `_generatePairCode`: Kullanici icin eslesme kodu olusturur.
- `_copyPairCode`: Uretilen eslesme kodunu panoya kopyalar ve tema uyumlu basari mesaji gosterir.
- `_enterPairCode`: Girilen kodla partner eslesmesi yapar.
- `_confirmUnpair`: Eslesmeyi bitirmeden once tema uyumlu onay dialogu acar.
- `_unpairPartner`: Iki kullanici arasindaki eslesme verilerini Firestore uzerinden temizler.
- `_buildProfileCard`: Profil/uyelik bilgisini monokrom avatarla kompakt bicimde gosterir.
- `_buildSignOutButton`: Oturum acikken Ayarlar sayfasinin en altinda tam genislikte, tehlike rengiyle belirginlestirilmis cikis butonunu olusturur.
- `_buildSettingsCard`: Ayarlar alt bolumleri icin ortak baslik, aciklama, yuzey, kenarlik ve golge kabugu saglar.
- `_buildPairingSection`: Giris, yukleme, eslesmemis ve eslesmis durumlarini tek kompakt kart icinde yonetir.
- `_buildPairingStatusBadge`: Eslesme karti basliginda baglanti durumunu notr nokta veya yukleme gostergesiyle belirtir.
- `_showNicknameEditor`: Partner hesap adini ve mevcut takma adi canli onizlemeli alt panele aktarir.
- `_savePartnerNickname`: Takma adi `users/{uid}.partnerNickname` alanina yazar; bos degerde alani Firestore kaydindan siler.
- `_buildNicknameSummary`: Takma ad, hesap adi ve duzenleme eylemini eslesme kartinda kompakt bir kontrol satiri olarak gosterir.
- `_buildThemeSegment`: Acik/koyu tema arasinda 280ms kayan monokrom segment kontrolunu olusturur.
- `_buildNotificationOption`: Ikon, aciklama ve siyah-beyaz switch iceren ayiracli bildirim satirini olusturur.

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
- `_buildPartnerPage`: Eslesilen partnerin son cizimini beyaz/seffaf cam yuzeyde, durumunu kutusuz satirda ve mini not isaretini baslikta gosterir.
- `_buildMyStatusPage`: Kullanicinin kendi durumunu gosterir.
- `_buildCardShell`: Partner, eslesme ve Durumum sayfalari icin tek `BackdropFilter` katmanli yari saydam cam kart kabugunu olusturur.
- `_buildHeaderRow`: Inter tipografili kart basligini, seffaf sayfa gostergesini, mini bildirim noktasini ve cerceveli ikon alanini uretir.
- `_buildStatusBubble`: Durum ikonunu gri dolgu kullanmadan ince cerceveli, kompakt yuvarlak alanda gosterir.
- `_statusIconData`: Firestore'daki durum ikon anahtarlarini Material ikonlara cevirir.
- `_buildStatusMark`: Yeni ikon anahtarlarini ikon, eski emoji kayitlarini metin olarak gosterir.
- `_showStatusPicker`: Erisilebilirlik kontrastina uyarlanan tek `BackdropFilter` katmanli iOS/Liquid Glass bottom sheet'i; mevcut paylasim, hazir durum, ozel durum, mini not ve cizim akislarini yonetir.
- `_buildSharedItemsSection`: Kullanicinin aktif mini not ve cizimini kompakt kartlarda gosterir; onayli silme islemlerini yonetir.
- `_buildSharedSketchCard`: Aktif cizimi ayri baslik/silme satiri ve oran korumali buyuk onizleme ile gosterir; onizlemeye dokunuldugunda detay panelini acar.
- `_statusButton`: Hazir durum seceneklerini yatay, ince cerceveli ve dokunma geri bildirimli butonlar olarak uretir.
- `_updateStatus`: Kullanicinin `statusIcon`, `statusText` ve `lastUpdated` alanlarini Firestore'a yazar.
- `_sendPartnerNote`: Partner kartinda gorunecek `partnerNote` bilgisini Firestore'a yazar ve partner bildirimini tetikler.
- `_deletePartnerNote`: Gonderilen mini not alanlarini Firestore dokumanindan temizler.
- `_showSketchComposer`: Tek blur katmanli Liquid Glass cizim panelini acar, cizim gonderme sonucunu ve tema uyumlu geri bildirimi yonetir.
- `_SketchComposer`: Normalize stroke cizimini, animasyonlu renk secimini, geri alma/temizleme araclarini ve bos/gonderiliyor durumlarina sahip gonderme aksiyonunu yonetir.
- `_SketchPainter`: Normalize cizgi verisini cizer; `fitToContent` acikken yalnizca kompakt yatay onizlemelerde cizim sinirlarini bulup en-boy oranini koruyarak ortalar.
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
Eslesme ayarlari icin `users/{uid}` dokumaninda kullanilan temel alanlar:

```text
- pairCode
- pairedWith
- partnerNickname
```

`partnerNickname` yalnizca takma adi veren kullanicinin dokumaninda tutulur; bos kaydedildiginde alan silinir ve partnerin hesap adi yeniden kullanilir.

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
- Haftalik Gunun Puani ekraninda gosterilecek istatistikleri urun karariyla belirlemek.
- FCM server key ve OpenWeather API key gibi client icindeki gizli bilgileri backend tarafina tasimak.
- Genel lint uyarilarini kademeli temizlemek.
