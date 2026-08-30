# Ozet App Gelistirme Notlari

Bu dokuman, uygulamada yaptigimiz tasarim ve davranis degisikliklerini takip etmek icin tutulur. Yeni bir ozellik, tasarim karari veya onemli refactor yapildiginda burasi guncellenecek.

## Uygulama Ozeti

Ozet App, Firebase tabanli bir Flutter haber/ozet uygulamasidir.

- Kullanici Firebase Auth ile e-posta/sifre veya Google hesabi ile giris yapar.
- Splash ekrani mevcut oturuma gore kullaniciyi ana sayfaya veya auth ekranina yonlendirir.
- Ana sayfa Firestore `news` koleksiyonunu 12 haberlik cursor sayfalariyla ve cevrim disi cache destegiyle okur; finans kartinin yerinde cihazda saklanan gunluk puan kartini gosterir.
- Haberler admin panelinden manuel eklenen alanlarla calisir: `title`, `summary`, `detail`, `source`, `createdAt`.
- Partner/eslesme islemleri callable Cloud Functions tarafindan dogrulanir; durum paylasimlari 24 saat sonra otomatik olarak pasif gorunur.
- Tema secimi cihazda, bildirim tercihleri ise cihaz ile kullaniciya ozel `user_private` belgesinde saklanir.

## Yapilan Degisiklikler

### Gunun Puani

- Finans karti kaldirildi; solda Partner/Eslesme ile Durumum, sagda Gunun Puani ile Detoks arasinda yatay gecis yapan iki alan tek ortak panelde birlestirildi.
- Kullanici ruh hali, enerji, ilerleme, kendine zaman ve huzur sorularini 1-10 arasinda puanlar.
- Bes sorunun esit agirlikli ortalamasi gunun puani olarak hesaplanir.
- Kullanici puanlamaya ek olarak en fazla 200 karakterlik istege bagli gun notu yazabilir.
- Kayit tamamlandiginda ana ekrandaki kart tarih, ortalama, kisa gun karsiligi ve varsa not onizlemesini gosterir.
- Ana ekrandaki Gunun Puani ve Detoks alanlarinin deger, sayfa gostergesi ve aksiyonlari acik temada siyah, koyu temada kirik beyaz ortak vurgu kullanir.
- `PartnerWidget` solda Partner/Eslesme ile Durumum sayfalarini, `DailyCardsWidget` sagda Gunun Puani ile Detoks sayfalarini ayni yatay kaydirma mekanizmasiyla gosterir.
- Bes soru uzun bir form yerine tek soruluk odakli adimlar halinde gosterilir; bes soru ve not adimi alti parcali ince ilerleme gostergesiyle izlenir.
- Her soruda 120px animasyonlu puan halkasi, cam aciklama kapsulu ve dokunma/suruklemeye aninda tepki veren 10 kademeli monokrom slider bulunur; puan gercekten degistiginde hafif haptik geri bildirim verilir.
- Yeni gun degerlendirmesinde ilk soru ve daha once cevaplanmamis sonraki sorular 5 puanla baslar; slider topu, puan halkasi ve aciklama ilk gorunumde birlikte dolu gelir.
- Slider altindaki `1`, `5` ve `10` etiketleri topun kullandigi ayni 1-10 koordinat hesabina tasindi; `5` etiketi geometrik merkez yerine gercek `4/9` konumunda top ile dikey hizalanir.
- Soru karti ile geri/ileri navigasyon grubu birlikte 14px asagi tasindi. 112px Ileri butonunun dar ekranda tasmasini engellemek icin ic dolgusu azaltildi ve metni esnek hale getirildi.
- Son adimda gunun ortalamasi ve kisa sonucu gosterilir; kullanici istege bagli notunu burada ekler.
- Degerlendirme ekrani blur ust/alt bar, tek ana cam soru paneli, dairesel puan gostergesi, saydam slider alani ve cam sonuc/not adimiyla Liquid Glass diline tasindi.
- Soru ve sonuc kartlari ayni ust hizada baslar. Kart ici navigasyon kaldirilarak kartlar kisaltildi; geri kontrolu kartin hemen altindaki satirin solunda, `Ileri` butonu 112x44 olcusunde sagda gosterilir. `Gun kartini olustur/guncelle` butonu geri kontrolunden sonra kalan yatay alani doldurur ve kartin sag kenariyla hizalanir. Sonuc adimindaki sabit blur alt bar kaldirildi.
- Ayni gunun kaydi karta yeniden basilarak duzenlenebilir.
- Kayitlar kullanici/guest anahtarina gore `SharedPreferences` icinde JSON olarak tutulur; haftalik istatistikler bu kayitlardan cihazda hesaplanir.
- Ana karttaki gecmis ikonu kayitlari ay bazinda gruplanmis, yeniden eskiye sirali arsiv ekraninda acar.
- Gecmis gun kartina basildiginda bes soru puani, gun sonucu ve tam not ayri detay ekraninda gosterilir; silme ve gecmis gunu duzenleme eklenmedi.
- Gun karti detayi ve gecmis listesindeki turkuaz vurgu kaldirildi; puan, deger ve ilerleme cizgileri acik temada siyah, koyu temada kirik beyaz ortak vurgu kullanir.
- Her kayit soru seti surumunu tasir; sorular degistiginde eski gunlerin hangi duzenle puanlandigi korunur.
- Degerlendirme ekraninin ust barindaki istatistik ikonu 280ms fade/slide gecisiyle haftalik gorunumu acar.
- Istatistik ekrani son 7 gunun puan grafigini, haftalik ortalamayi, tamamlanan gun sayisini, bes soru basliginin ayri ortalamasini ve onceki 7 gune gore puan farkini gosterir.
- Eksik gunler grafikte bos kalir; ortalamalar yalnizca kayit bulunan gunlerden hesaplanir ve onceki hafta verisi yoksa karsilastirma uretilmez.
- Istatistik ekranina tek parca kayan `Hafta / Takvim` secicisi eklendi; takvim mevcut gunluk puanlari aylik gorunumde sunar ve yeni bir istatistik parametresi uretmez.
- `Hafta / Takvim` icerik gecisindeki alttan gelme hareketi kaldirildi; iki gorunum ust kenara sabitlenerek 240ms saydamlik ve `0.985 -> 1.0` olcek gecisiyle degisir.
- Takvim pazartesi baslangicli sabit 6x7 izgara kullanir. Kayitli gunlerin monokrom dolgu yogunlugu gunun puanina gore degisir; gelecek aya gecis kapali tutulur.
- Koyu temada kayitsiz gunler koyu cam yuzeyde tutulur; kayitli gunler sinirli puan yogunlugu, daha belirgin kenarlik ve buyutulmus gun/puan metniyle ayrilir. Bugun 2px kirik beyaz cerceve kullanir.
- Kayitli bir takvim gunune dokunuldugunda mevcut `DailyScoreDetailScreen` acilir; bos ve gelecek gunler etkilesimsizdir.

### Auth Ekrani

- Giriş/Kayit ekrani ortak `AppThemePalette`, Inter tipografi ve monokrom Liquid Glass yuzeylerle yeniden tasarlandi; eski mavi/lacivert vurgu sabitleri kaldirildi.
- Giriş/Kayit gecisi tek parca kayan segment bara donusturuldu.
- Form gecisi alttan kayma kullanmadan ustten sabit 240ms fade ve `0.985 -> 1.0` olcek animasyonuyla calisir; kayit alaninin yuksekligi `AnimatedSize` ile yumusak degisir.
- E-posta, sifre ve ad alanlari 14px koseli yari saydam cam yuzey, monokrom odak cercevesi, Inter metin ve klavye ileri/tamam aksiyonlari kullanir.
- Google girisi logo yerine buton olarak tasarlandi.
- Sifre goster/gizle ozelligi eklendi.
- Sifremi unuttum Firebase password reset akisina baglandi.
- Gelistirme icin gecici girissiz devam aksiyonu uzun metin butonu yerine sag ustteki 42x42 ortak cam kapatma kontrolune tasindi.
- Auth icerigi yeterli ekran yuksekliginde dikey merkezlenir, klavye veya kisa ekranlarda kaydirilir. Logo 124px yukseklige, segment ve ana butonlar 54px yukseklige buyutuldu; cam kapatma kontrolu logo basliginin sag ustune bindirilerek ayri satir boslugu kaldirildi.

### Ana Sayfa Haber Listesi

- Haberler ayri kart kabugu, dolgu ve golge yerine sayfa zeminindeki editoryal liste satirlari olarak gosterilir.
- Kategori ve kaynak etiketleri seffaf zemin, ince notr cerceve ve tema uyumlu yazi rengiyle gosterilir.
- `createdAt` varsa tarih gosteriliyor, yoksa gizleniyor.
- Satirin tamami dokunmayla mevcut detay dialogunu acar ve tema uyumlu hafif basma tepkisi verir.
- `detail` alani bossa detay ekraninda `summary` gosterilir.
- Baslik ve en fazla uc satirlik ozet korunur; gereksiz `Detayi oku` satiri kaldirilir ve haberler `1px` notr cizgiyle ayrilir.
- Sunum degisikligi Firestore alanlarini, yayin filtresini, RSS/admin akislarini ve detay acma davranisini degistirmez.
- Okunmamis haberler metadata satirindaki kucuk notr nokta ve daha guclu baslik agirligiyla ayrilir; haber acildiginda nokta aninda kalkar ve baslik daha sakin tona gecer.
- Okundu bilgisi Firestore haber belgesine yazilmaz. Kullanici/guest bazinda `SharedPreferences` icinde tutulur ve yerel listenin sinirsiz buyumemesi icin son 500 haber kimligi korunur.
- Haberler 12 gorunur kayitlik cursor gruplariyla yuklenir; ayni koleksiyondaki taslak sayfalari kullaniciya buton bastirmadan otomatik atlanir. Kullanici listenin sonuna yaklastiginda sonraki grup otomatik alinir; normal durumda manuel yukleme butonu gosterilmez ve ag hatasinda Firestore cache kullanilir.

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
- Ana sayfadaki Partner/Durumum ve Gunun Puani/Detoks alanlari haber akistan farkli tek ortak yuzeyde, ortadaki ince dikey cizgiyle ayrilir; ayri kart kabuklari ve golgeleri kullanilmaz.
- Ortak panel 18px blur, saydam beyaz tint, capraz yansima ve ust kenar isigi kullanir. Ince dis kontur, yakin temas golgesi, genis ortam golgesi ve alttaki 6px nefes alani karti rengini degistirmeden yuzeyden ayirir; kartin kendi yuksekligi 158px olarak korunur.
- Eslesme yok, Gunun Puani ve Detoks alanlarinda yalnizca kucuk bolum etiketi, ana durum/deger ve gerekli kisa eylem metni tutulur; buyuk dekoratif lens ve aciklama kalabaligi kullanilmaz.
- Yatay ayiricilar kaldirildi; tum yari panel dokunulabilir kalirken iki konumlu sayfa gostergesi, kisa eylem ve sade chevron tek satirlik kompakt footer icinde hizalanir.
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
- Partner ve Gunun Puani/Detoks alanlari `embedded` modunda ana sayfanin ortak panel yuzeyini kullanir; kendi dis zemin, kenarlik ve golgelerini uretmez.
- Partner not paylastiysa kart basliginin yaninda kucuk bir bildirim noktasi gosterilir.
- Partner kartina basilinca partnerin son 3 durum/not/cizim paylasimi detay panelinde listelenir.
- Durum paylasimlarina `statusExpiresAt` yazilir; 24 saati gecen durumlar eski kayitlarda `lastUpdated` fallback'iyle birlikte notr duruma doner.

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
- Bildirim karti `Gunun Ozeti`, `Aksam Hatirlatmasi` ve `Partner Paylasimlari` olarak uc anlasilir tercihe indirildi; konu abonelikleri ve kullaniciya ozel tercihler birlikte guncellenir.
- Ayarlar sayfasindaki ana kartlar arasindaki dikey bosluk 16px'ten 8px'e indirildi; kartlarin ic bosluklari korunur.
- Ana sayfa, Ayarlar ve Gunun Puani koyu tema zemini `#0D0D0E`; kart/cam yuzeyleri `#1C1C1E` ve guclu kontrol yuzeyleri `#2C2C2E` ortak paletine baglandi.

### Uygulama Mesajlari

- Hata, basari ve bilgi mesajlari icin Inter tipografili `AppFeedback` yardimci sinifi eklendi.
- Auth ve Ayarlar ekranlarindaki snackbar mesajlari uygulamanin acik/koyu tema diline uygun kart gorunumune tasindi.
- Eslesmeyi bitirme onay dialogu tema uyumlu, yuvarlak koseli ve daha sakin bir tasarima guncellendi.
- Global `SnackBarThemeData` eklendi; ileride duz `SnackBar` kullanilsa bile genel tema dili korunur.
- Tekrar denenebilir hatalarda `AppFeedback` icinde `Tekrar dene` aksiyonu gosterilir; haber akisinda ilk yukleme ve sayfalama hatalari satir ici tekrar deneme durumu kullanir.

## Onemli Classlar

### `MyApp` - `lib/main.dart`

Uygulamanin MaterialApp, tema ve genel baslangic yapisini kurar. `themeNotifier` ile acik/koyu tema degisimini dinler.

### `AppThemePalette` - `lib/theme/app_theme_palette.dart`

Ana sayfa, Ayarlar ve Gunun Puani ekranlarinin ortak koyu zemin, yuzey, guclu yuzey, metin ve ikincil metin sabitlerini tutar; ekranlar arasinda ton farki olusmasini engeller.

### `SplashScreen` - `lib/screens/splash_screen.dart`

Uygulama acilis ekranidir. Firebase oturumu varsa `HomeScreen`, yoksa `AuthScreen` acar.

### `AuthScreen` - `lib/screens/auth_screen.dart`

Giris/kayit ekranidir. E-posta/sifre, Google girisi, sifre sifirlama ve gecici girissiz devam akislarini icerir. Giris basligi ilk ve tekrar gelen kullanicilara birlikte uyan notr `Hos geldin` metnini kullanir.

### `NewsWebViewScreen` - `lib/screens/news_webview_screen.dart`

RSS/manual haber kaynak linklerini uygulama icinde WebView ile acar; ustte haber basligi, site adresi, yenile aksiyonu ve yukleme ilerleme cizgisi gosterir.

### `HomeScreen` - `lib/screens/home_screen.dart`

Ana haber akisini, Gunun Puani kartini, partner/detoks alanini ve haber detay dialogunu yonetir. Ana sayfa ust bari acik/koyu temaya uyarlanan kompakt Liquid Glass yuzey, dairesel ayarlar kontrolu ve bagimsiz merkezlenen marka alani kullanir.

### `_buildNewsFeed` ve `_buildNewsListItem` - `lib/screens/home_screen.dart`

Yayindaki Firestore haberlerini filtreleyip `ListView.separated` ile editoryal satirlara donusturur; etiket, tarih, baslik, ozet, erisilebilirlik etiketi ve mevcut detay dialogu gecisini yonetir.

### `_buildHomeTopBar`, `_buildHomeBrand`, `_openSettings` - `lib/screens/home_screen.dart`

Ana sayfanin kaydirmaya gore saydamligi degisen Liquid Glass ust barini, logo olcegini ve dokunsal geri bildirimli ayarlar gecisini yonetir. Ortak cam bileseni yuksek saydamlik, capraz yansima ve cevresel renk halkasi kullanir; `7` sigma blur yalnizca arka plan ayrimi icin yardimci katmandir. Logo ile slogan arasinda ayirici cizgi kullanilmaz.

### `LiquidGlassSliverAppBar` ve `LiquidGlassIconButton` - `lib/widgets/liquid_glass_app_bar.dart`

Ana sayfa ve ayarlar ekraninda ortak kullanilan saydam ust bari, cizgisiz yansima yuzeyini ve dokunsal geri bildirimli beyaz cam ikon lensini olusturur. Ayarlar ve geri kontrolleri 42x42 beyaz cam kabuk, 40x40 merkezlenmis dokunma alani ve optik olarak dengelenmis ikon boyutlari kullanir.

### `HomePanelIcon`, `HomePanelPageIndicator` ve `HomePanelFooter` - `lib/widgets/home_panel_controls.dart`

Ana sayfadaki Partner ve Gunun Puani alanlarinda kullanilan kucuk cam ikonu, iki konumlu sayfa gostergesini ve kisa eylem ile sade chevron iceren kompakt footer yerlesimini olusturur. Dar yari panelde metin tasmasini engeller.

### `DailyScoreEntry` - `lib/models/daily_score_entry.dart`

Bes soru puanini, gun notunu, tarih anahtarini, gunluk ortalamayi ve kisa sonuc etiketini tasir.

### `DailyScoreStorage` - `lib/services/daily_score_storage.dart`

Gunluk puan kayitlarini oturum acmis kullanici veya misafir icin ayri cihaz anahtarlarinda JSON olarak saklar; tum gecerli kayitlari bozuk verileri atlayarak yeniden eskiye sirali okuyabilir.

### `NewsReadStorage` - `lib/services/news_read_storage.dart`

Firestore haber verisini degistirmeden okunan dokuman kimliklerini kullanici/guest bazinda cihazda saklar; tekrarli kimlikleri temizler ve son 500 kayitla sinirlar.

### `DailyScoreStatistics`, `DailyScoreDayPoint` ve `DailyScoreCalendarMonth` - `lib/models/daily_score_statistics.dart`

Son 7 takvim gunu ile onceki 7 gunu ayirir; gunluk grafik noktalarini, haftalik ortalamayi, tamamlanan gun sayisini, soru ortalamalarini ve iki hafta arasindaki puan farkini saf ve test edilebilir bicimde hesaplar. `DailyScoreCalendarMonth`, secilen ayin gun sayisini, pazartesi bazli baslangic boslugunu ve gun-kayit eslesmesini uretir.

### `NewsFeedService` ve `PaginatedNewsFeed`

Firestore haberlerini `createdAt` sirasiyla 12 gorunur kayitlik cursor gruplarinda getirir. Sunucu istegi basarisizsa yerel cache'e duser; widget sona yaklasmayi dis `ScrollController` ile algilar, otomatik yukleme, tekrar deneme ve konumu bozmayan sessiz yenilemeyi yonetir.

### `NotificationPreferencesService`

Gunun ozeti ve aksam hatirlatmasi icin FCM topic aboneliklerini, partner bildirim tercihini ve `user_private/{uid}` altindaki uzak tercih kopyasini yonetir; eski `aksamOzeti` anahtarini yeni modele tasir.

### `PartnerStatusView`

Partner durumunun halen aktif olup olmadigini `statusExpiresAt`, eski kayitlarda ise `lastUpdated + 24 saat` uzerinden hesaplar ve suresi dolmus durumlari notr sunuma cevirir.

### `DailyScoreScreen` - `lib/screens/daily_score_screen.dart`

Bes soruyu tek tek sunan ilerlemeli akisi, dogrudan dokunma/surukleme algilayan 10 kademeli puan barini, Liquid Glass sonuc/not adimini ve gun karti olusturma/guncelleme islemini yonetir. `_openStatistics`, ust bardaki grafik kontrolunden istatistik ekranina haptik geri bildirimli fade/slide gecisini kurar.

### `_GlassSurface` ve `_ScorePalette` - `lib/screens/daily_score_screen.dart`

Degerlendirme ekraninin blur cam panel kabugunu ve acik/koyu temadaki monokrom yuzey, metin, kenarlik, kontrol ve vurgu renklerini tek noktadan yonetir.

### `DailyScoreStatisticsScreen` - `lib/screens/daily_score_statistics_screen.dart`

Yerel gunluk kayitlari yukler, yenileme/hata durumlarini yonetir ve onaylanan bes haftalik metrigi Gunun Puani sayfasiyla ayni Inter tipografi, monokrom palet ve 24px Liquid Glass kartlarla sunar. `_selectView` haftalik/takvim gecisini, `_moveMonth` gelecek ay sinirli ay gezinmesini, `_openEntry` ise takvimden gun detayina gecisi yonetir.

### `DailyScoreStatisticsViewControl` ve `DailyScoreCalendarView` - `lib/widgets/daily_score_calendar_view.dart`

Kayan monokrom `Hafta / Takvim` secicisini ve aylik 42 hucreli Liquid Glass takvimi olusturur. `_CalendarDayCell` bugunu vurgular, puan yogunlugunu siyah/beyaz dolgu ile ifade eder ve yalnizca gecerli kaydi bulunan gunleri etkilesimli yapar.

### `_WeeklyChartPainter`, `_StatisticsGlassSurface`, `_StatisticsPalette`

Yedi gunluk cizgi/alan grafigini kutuphane bagimliligi olmadan cizer; istatistik kartlarinin cam kabugunu ve acik/koyu tema renklerini tek yerde yonetir.

### `DailyScoreHistoryScreen` - `lib/screens/daily_score_history_screen.dart`

Gunluk kayitlari ay basliklari altinda listeler; bos, yukleniyor ve hata durumlarini yonetir ve secilen kaydi detay sayfasina acar.

### `DailyScoreDetailScreen` - `lib/screens/daily_score_history_screen.dart`

Tek bir gunun tarihini, ortalamasini, sonuc etiketini, bes soru puanini ve tam notunu salt okunur olarak gosterir.

### `DailyCardsWidget` - `lib/widgets/daily_cards_widget.dart`

Ana sayfanin sag alaninda Gunun Puani ve Detoks sayfalarini iki nokta gostergeli yatay `PageView` ile gosterir; `embedded` modunda dis kart kabugunu ortak panele birakir. Bos durumda yalnizca degerlendirme cagrisi, kayitli durumda puan ve kisa sonuc, Detoks sayfasinda kazanilan sure ile haber sayisi gosterilir.
### `SettingsScreen` - `lib/screens/settings_screen.dart`

Profil, tema, bildirim tercihleri ve partner eslesme ayarlarini; responsive genislik, ortak Liquid Glass ust bar ve monokrom kart sistemiyle yonetir.

### `_SettingsPalette` - `lib/screens/settings_screen.dart`

Ayarlar ekraninin acik/koyu tema yuzeylerini, metinlerini, kenarliklarini, vurgu ve tehlike renklerini tek noktadan uretir; koyu temel degerleri `AppThemePalette` uzerinden alir.

### `_NicknameEditorSheet` - `lib/screens/settings_screen.dart`

Partner takma adini canli kart onizlemesiyle duzenleyen, klavye bosluguna uyum saglayan ve kaydetme/kaldirma durumlarini yoneten Liquid Glass alt paneldir.

### `PartnerWidget` - `lib/widgets/partner_widget.dart`

Partnerin paylasim alani ile kullanicinin kendi Durumum alanini yatay gecisle gosterir. `embedded` modunda ortak ana panel icin dis kart kabugunu kapatir; bos eslesme yalnizca durum ve `Eslestir`, Durumum sayfasi mevcut durum ve `Guncelle` eylemini gosterir. Eslesmis partnerin cizim onizlemesi korunur; durum satiri kompakt footer icinde kalir.

### `AppFeedback` - `lib/widgets/app_feedback.dart`

Uygulama genelindeki hata, basari ve bilgi snackbar mesajlarini Inter tipografili, tema uyumlu tek bir kart stilinde gosterir; gerektiginde tekrar deneme aksiyonu sunar.

## Onemli Fonksiyonlar

### Auth

- `_signInWithGoogle`: Google hesabi ile Firebase Auth girisi yapar.
- `_submitAuthForm`: E-posta/sifre ile giris veya kayit islemini yapar.
- `_resetPassword`: Girilen e-posta adresine sifre sifirlama baglantisi gonderir.
- `_buildModeSwitch`: Giris/Kayit arasindaki kayan segment kontrolunu olusturur.
- `_buildSkipButton`: Gelistirme icin giris yapmadan ana sayfaya gecis saglar.

### Home

- `_saveDeviceToken`: FCM token bilgisini yalnizca kullanicinin okuyabildigi `user_private/{uid}` belgesine yazar ve token yenilenmesini dinler.
- `_loadTodayScore`: Bugunun daha once kaydedilmis puanini cihazdan yukler.
- `_openDailyScore`: Puanlama ekranini acar, donen gun kaydini saklar ve ana karti yeniler.
- `_openDailyScoreHistory`: Aylik gecmis kayit listesini uygulama icinde acar.
- `_buildLiveWidgets`: `PartnerWidget` ve `DailyCardsWidget` icin 18px blur, dengeli beyaz tint, yansima, kenar isigi ve merkezdeki dikey ayraci kullanan ortak Liquid Glass paneli olusturur.
- `_buildNewsFeed`: `PaginatedNewsFeed` ile yalnizca mobilde gorunebilir haberleri sayfali/cache destekli yukler; satirlari acik ve koyu temada hafif guclendirilmis 1px ayiraclarla boler.
- `_buildNewsListItem`: Admin panelinden gelen mevcut haber alanlarini kart kabugu olmadan dokunulabilir editoryal liste satirinda gosterir.
- `_loadReadNewsIds`: Aktif kullanici veya guest icin cihazda saklanan okundu kimliklerini ana sayfa durumuna yukler.
- `_markNewsAsRead`: Haber detayini acarken gorsel durumu aninda yeniler ve dokuman kimligini `NewsReadStorage` ile kalici hale getirir.
- `_isVisibleNews`: RSS taslaklarini ve reddedilen haberleri mobil akistan filtreler.
- `_textField`: Firestore metin alanlarini bosluklardan arindirarak guvenli okur.
- `_buildNewsMetaChip`: Kategori ve kaynak bilgisini seffaf zeminli, ince cerceveli tema uyumlu kompakt etiket olarak gosterir.
- `_formatCreatedAt`: `createdAt` veya `publishedAt` alanini kart uzerinde okunabilir kisa tarih formatina cevirir.
- `_showModernDetailModal`: Haber detayini ortada acilan modern dialog olarak gosterir.
- `_openSourceUrl`: Haber kaynaginin URL bilgisini dogrular, detay dialogunu kapatir ve `NewsWebViewScreen` ekranini uygulama icinde acar.

### Daily Score

- `_selectScore`: Sliderdan gelen 1-10 degerini aktif soruya gecikmesiz yazar ve deger degistiginde secim haptigi verir.
- `_buildProgress`: Bes soru ile not adimini alti parcali animasyonlu ilerleme satirinda gosterir.
- `_buildQuestionStep`: Aktif soruyu, dairesel puan gostergesini ve 10 kademeli slideri tek Liquid Glass panelde olusturur.
- `_buildNoteStep`: Gun ortalamasi, sonuc etiketi ve istege bagli 200 karakterlik not alanini son adimda gosterir.
- `_buildQuestionNavigation`: Soru adimlarinda geri ve ileri kontrollerini cam kartin disindaki alt navigasyon satirinda konumlandirir.
- `_buildActions`: Sonuc/not adimindaki geri ve kaydetme eylemlerini klavye guvenli blur alt barda yonetir.
- `DailyScoreStorage.getAll`: Gecerli kayitlari ayristirir, bozuk olanlari atlar ve tarih azalan sirada dondurur.
- `_reload`: Gecmis ekraninin yerel kayit listesini yeniden yukler.
- `_openEntry`: Secilen gun kaydini `DailyScoreDetailScreen` icinde acar.
- `_groupByMonth`: Sirali gun kayitlarini ay/yil basliklari altinda gruplar.

### Settings

- `_loadSettings`: Bildirim tercihlerini cihazdan okur.
- `_saveNotificationSetting`: Secilen bildirim tercihini ekranda aninda gunceller ve `SharedPreferences` icine kaydeder.
- `_updateTheme`: Tema tercihini kaydeder ve uygulamaya uygular.
- `_generatePairCode`: `createPairCode` callable function'i ile sunucuda benzersiz eslesme kodu olusturur.
- `_copyPairCode`: Uretilen eslesme kodunu panoya kopyalar ve tema uyumlu basari mesaji gosterir.
- `_enterPairCode`: `pairWithCode` callable function'i ile kodu sunucuda dogrulatip iki kullaniciyi transaction icinde eslestirir.
- `_confirmUnpair`: Eslesmeyi bitirmeden once tema uyumlu onay dialogu acar.
- `_unpairPartner`: `endPairing` callable function'i ile iki kullanici arasindaki eslesmeyi transaction icinde temizler.
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
- `createPairCode`, `pairWithCode`, `endPairing`: Kod uretme, karsilikli eslestirme ve eslesmeyi bitirme islemlerini sunucu transaction'lariyla yapar.
- `notifyPartner`: Karsilikli eslesmeyi ve alicinin tercihini dogrular, tokeni `user_private` belgesinden okuyup Admin SDK ile bildirim gonderir.
- `sendMorningDigest` ve `sendEveningCheckIn`: Europe/Istanbul saat diliminde ilgili topic abonelerine zamanlanmis bildirim yollar.
- `sendAdminBroadcast`: Yalnizca admin yetkili kullanicinin `all` topic'ine panelden bildirim gondermesini saglar.
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
- `_updateStatus`: Kullanicinin `statusIcon`, `statusText`, `lastUpdated` ve 24 saatlik `statusExpiresAt` alanlarini Firestore'a yazar.
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
- `_notifyPartner`: `notifyPartner` callable function'ini cagirir; backend eslesmeyi ve partner bildirim tercihini dogruladiktan sonra Admin SDK ile bildirim gonderir.

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
Okundu kimlikleri Firestore modeline eklenmez; cihazda `news_read_ids_v1_{uid|guest}` anahtariyla saklanir.
Partner durumuna `statusExpiresAt` eklenir; hassas FCM tokeni ve bildirim tercihleri `user_private/{uid}` belgesinde tutulur. `pair_codes/{code}` belgelerine mobil istemci dogrudan erisemez.

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
## Guvenlik, Cache ve Hata Izleme

- Firestore mobil cache'i 40 MB sinirla etkinlestirildi; haber servisi ag hatasinda acikca cache kaynagina duser.
- `firestore.rules`, eslesme alanlarini istemci yazimina kapatir; ozel token/tercih belgelerini yalnizca sahibine acar ve admin koleksiyonlarini yetkiyle sinirlar.
- Android Crashlytics Gradle eklentisi eklendi; release modunda Flutter framework ve platform hatalari Firebase Crashlytics'e fatal hata olarak kaydedilir.
- Firebase Android SDK metadata uyumu icin Kotlin Gradle eklentisi `2.3.20` surumune ve yeni `compilerOptions` DSL'ine tasindi. Pub cache ile proje farkli Windows suruculerinde oldugu icin bozuk Kotlin cache yollarini onlemek uzere incremental Kotlin derlemesi kapatildi.
- Client icindeki eski FCM server key ve kullanilmayan OpenWeather anahtari/konum izinleri kaldirildi. Admin ve partner bildirimleri backend uzerinden gonderilir.

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
- Functions, Firestore rules ve hosting'i birlikte yayinlayip gercek cihazda eslesme, zamanlanmis bildirim ve Crashlytics kaydini dogrulamak.
- Genel lint uyarilarini kademeli temizlemek.
