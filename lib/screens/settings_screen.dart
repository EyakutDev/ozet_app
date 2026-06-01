import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- BU SATIR ÇOK ÖNEMLİ, EKLENDİ
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ozet_app/screens/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozet_app/main.dart'; // themeNotifier için şart!
import 'package:ozet_app/widgets/app_feedback.dart';
import 'dart:ui' as ui;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // Tema durumunu themeNotifier'dan alıyoruz
  bool get isDark => themeNotifier.value == ThemeMode.dark;
  // Toggle Değişkenleri
  bool gununOzeti = true;
  bool aksamOzeti = true;
  bool sessizMod = false;
  // Eşleşme Değişkenleri
  String? _generatedCode;
  String? _pairedWith;
  String? _partnerNickname;
  final TextEditingController _pairCodeController = TextEditingController();
  final TextEditingController _partnerNicknameController =
      TextEditingController();
  bool _isPairingLoading = false;
  // Scroll pozisyonunu takip etmek için controller
  final ScrollController _scrollController = ScrollController();
  // Sayfa kaydırıldı mı kontrolü (10px üzeri = true)
  bool _isScrolled = false;
  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle
    _checkExistingCode(); // Varsa mevcut kodu yükle
    // Scroll dinleyicisi: Sayfa kaydırıldığında AppBar'ı blur yap
    _scrollController.addListener(() {
      // 10 pixel üzeri kaydırıldıysa ve henüz blur aktif değilse
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true); // Blur efektini aktif et
      }
      // Başa dönüldüyse ve blur hala aktifse
      else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false); // Blur efektini kapat
      }
    });
  }

  @override
  void dispose() {
    _pairCodeController.dispose();
    _partnerNicknameController.dispose();
    _scrollController
        .dispose(); // Memory leak önlemek için controller'ı temizle
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gununOzeti = prefs.getBool('gununOzeti') ?? true;
      aksamOzeti = prefs.getBool('aksamOzeti') ?? true;
      sessizMod = prefs.getBool('sessizMod') ?? false;
    });
  }

  // Kullanıcının halihazırda oluşturduğu bir kod var mı kontrol et
  Future<void> _checkExistingCode() async {
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (doc.data()!.containsKey('pairCode')) {
        setState(() {
          _generatedCode = data['pairCode'];
        });
      }
      setState(() {
        _pairedWith = data['pairedWith'] as String?;
        _partnerNickname = data['partnerNickname'] as String?;
        _partnerNicknameController.text = _partnerNickname ?? '';
      });
    }
  }

  Future<void> _updateTheme(bool isDarkTheme) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      themeNotifier.value = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
    });
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
  }

  // === 1. KOD OLUŞTURMA (Benim İçin) ===
  Future<void> _generatePairCode() async {
    if (currentUser == null) return;
    setState(() => _isPairingLoading = true);
    // 6 Haneli Rastgele Kod
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = List.generate(
      6,
      (index) => chars[DateTime.now().microsecondsSinceEpoch % chars.length],
    ).join();
    try {
      // Kodu Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({
            'pairCode': code,
            'email': currentUser!.email,
            'pairedWith': null,
          }, SetOptions(merge: true));
      setState(() {
        _generatedCode = code;
        _isPairingLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() => _isPairingLoading = false);
    }
  }

  // === 2. KOD GİRME VE EŞLEŞME (Eşim İçin) ===
  Future<void> _enterPairCode() async {
    String inputCode = _pairCodeController.text.trim().toUpperCase();
    if (inputCode.isEmpty || currentUser == null) return;
    setState(() => _isPairingLoading = true);
    try {
      // Bu koda sahip kullanıcıyı bul
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pairCode', isEqualTo: inputCode)
          .get();
      if (querySnapshot.docs.isEmpty) {
        AppFeedback.show(
          context,
          "Hatalı kod girdin.",
          type: AppFeedbackType.error,
        );
        setState(() => _isPairingLoading = false);
        return;
      }
      String partnerUid = querySnapshot.docs.first.id;
      if (partnerUid == currentUser!.uid) {
        AppFeedback.show(
          context,
          "Kendinle eşleşemezsin.",
          type: AppFeedbackType.error,
        );
        setState(() => _isPairingLoading = false);
        return;
      }
      // Batch işlemi ile iki tarafı da güncelle
      WriteBatch batch = FirebaseFirestore.instance.batch();
      // Ben -> Onu ekle
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid),
        {'pairedWith': partnerUid, 'pairCode': FieldValue.delete()},
        SetOptions(merge: true),
      );
      // O -> Beni ekle
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(partnerUid),
        {'pairedWith': currentUser!.uid, 'pairCode': FieldValue.delete()},
        SetOptions(merge: true),
      );
      await batch.commit();
      AppFeedback.show(
        context,
        "Eşleşme başarılı.",
        type: AppFeedbackType.success,
      );
      _pairCodeController.clear();
      setState(() {
        _generatedCode = null;
        _pairedWith = partnerUid;
        _isPairingLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
      AppFeedback.show(
        context,
        "Eşleşme tamamlanamadı. Lütfen tekrar dene.",
        type: AppFeedbackType.error,
      );
      setState(() => _isPairingLoading = false);
    }
  }

  Future<void> _savePartnerNickname() async {
    if (currentUser == null) return;

    final nickname = _partnerNicknameController.text.trim();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .set({
          'partnerNickname': nickname.isEmpty ? FieldValue.delete() : nickname,
        }, SetOptions(merge: true));

    setState(() => _partnerNickname = nickname.isEmpty ? null : nickname);

    if (!mounted) return;
    AppFeedback.show(
      context,
      "Takma ad kaydedildi.",
      type: AppFeedbackType.success,
    );
  }

  Future<void> _confirmUnpair() async {
    if (currentUser == null || _pairedWith == null) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final mutedColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    final shouldUnpair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Eşleşmeyi bitir?",
          style: GoogleFonts.kadwa(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Partner durumunu artık göremezsin. İstersen daha sonra tekrar kodla eşleşebilirsin.",
          style: GoogleFonts.kadwa(
            color: mutedColor,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Vazgeç",
              style: GoogleFonts.kadwa(
                color: mutedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE57373).withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Bitir",
              style: GoogleFonts.kadwa(
                color: const Color(0xFFE57373),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldUnpair != true) return;
    await _unpairPartner();
  }

  Future<void> _unpairPartner() async {
    if (currentUser == null || _pairedWith == null) return;

    final partnerUid = _pairedWith!;
    final batch = FirebaseFirestore.instance.batch();
    final myRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid);
    final partnerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(partnerUid);

    batch.set(myRef, {
      'pairedWith': FieldValue.delete(),
      'partnerNickname': FieldValue.delete(),
      'pairCode': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.set(partnerRef, {
      'pairedWith': FieldValue.delete(),
      'partnerNickname': FieldValue.delete(),
      'pairCode': FieldValue.delete(),
    }, SetOptions(merge: true));

    await batch.commit();
    _partnerNicknameController.clear();

    setState(() {
      _pairedWith = null;
      _partnerNickname = null;
      _generatedCode = null;
    });

    if (!mounted) return;
    AppFeedback.show(
      context,
      "Eşleşme bitirildi.",
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerine göre ayarla
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color yaziRengi = isDarkMode ? Colors.white : Colors.black;
    final Color altYaziRengi = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    // Input ve Kart renkleri (Koyu mod uyumlu)
    final Color inputBgColor = isDarkMode
        ? const Color(0xFF2C2C2C)
        : Colors.grey[100]!;
    final Color inputBorderColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[300]!;
    // Buton renkleri
    final Color eslesmeRengi = const Color(0xFF0A2342);
    final Color acikGriButon = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey[100]!;
    final Color cardBgColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color cardBorderColor = isDarkMode
        ? Colors.grey[850]!
        : const Color(0xFFE9EEF4);
    final Color softShadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.grey.withValues(alpha: 0.28);
    final TextStyle kadwaBold = GoogleFonts.kadwa(
      fontWeight: FontWeight.bold,
      color: yaziRengi,
      fontSize: 18,
    );
    final TextStyle kadwaRegular = GoogleFonts.kadwa(
      color: yaziRengi,
      fontSize: 16,
    );
    final TextStyle kadwaLabel = GoogleFonts.kadwa(
      color: altYaziRengi,
      fontSize: 14,
    );
    final TextStyle kadwaSectionTitle = GoogleFonts.kadwa(
      fontWeight: FontWeight.bold,
      color: yaziRengi,
      fontSize: 24,
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // CustomScrollView: Scroll efektleri için gerekli
      body: CustomScrollView(
        controller: _scrollController, // Scroll pozisyonunu takip et
        slivers: [
          // SliverAppBar: Scroll ile birlikte çalışan AppBar
          SliverAppBar(
            pinned: true, // AppBar her zaman üstte sabit kalsın
            floating: false, // Aşağı kaydırınca gizlenmesin
            backgroundColor: Colors.transparent, // Şeffaf arka plan
            elevation: 0, // Gölge yok
            // Durum çubuğu (status bar) stilini ayarla
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent, // Durum çubuğu şeffaf
              statusBarIconBrightness: isDarkMode
                  ? Brightness
                        .light // Koyu temada açık ikonlar
                  : Brightness.dark, // Açık temada koyu ikonlar
              statusBarBrightness: isDarkMode
                  ? Brightness.dark
                  : Brightness.light,
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: yaziRengi),
              onPressed: () => Navigator.of(context).pop(),
            ),

            // flexibleSpace: AppBar'ın arka plan alanı
            flexibleSpace: ClipRect(
              // AnimatedSwitcher: İki widget arasında yumuşak geçiş yapar
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200), // Geçiş süresi
                child: _isScrolled
                    // KAYDIRINCA: Blurlu arka plan
                    ? BackdropFilter(
                        key: const ValueKey(
                          'blurred',
                        ), // AnimatedSwitcher için unique key
                        filter: ui.ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ), // Blur yoğunluğu
                        child: Container(
                          decoration: BoxDecoration(
                            // Yarı şeffaf arka plan (temaya göre)
                            color: isDarkMode
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    // BAŞTA: Normal scaffold rengi
                    : Container(
                        key: const ValueKey(
                          'solid',
                        ), // AnimatedSwitcher için unique key
                        decoration: BoxDecoration(color: scaffoldBg),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ayarlar",
                    style: kadwaSectionTitle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 18),
                  _buildProfileCard(
                    kadwaBold,
                    kadwaLabel,
                    yaziRengi,
                    altYaziRengi,
                    cardBgColor,
                    cardBorderColor,
                    softShadowColor,
                    acikGriButon,
                  ),
                  const SizedBox(height: 24),
                  // === EŞLEŞME BÖLÜMÜ ===
                  _buildPairingSection(
                    kadwaSectionTitle,
                    kadwaRegular,
                    kadwaLabel,
                    eslesmeRengi,
                    inputBgColor,
                    inputBorderColor,
                  ),
                  const SizedBox(height: 18),
                  // === GÖRÜNÜM BÖLÜMÜ ===
                  _buildSettingsCard(
                    title: "Görünüm",
                    titleStyle: kadwaSectionTitle,
                    cardBg: cardBgColor,
                    borderColor: cardBorderColor,
                    shadowColor: softShadowColor,
                    children: [
                      _buildThemeSegment(
                        isDark: isDark,
                        textColor: yaziRengi,
                        mutedColor: altYaziRengi,
                        inputBg: inputBgColor,
                        cardBg: cardBgColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // === BİLDİRİMLER ===
                  _buildSettingsCard(
                    title: "Bildirimler",
                    titleStyle: kadwaSectionTitle,
                    cardBg: cardBgColor,
                    borderColor: cardBorderColor,
                    shadowColor: softShadowColor,
                    children: [
                      _buildNotificationOption(
                        title: "Günün Özeti",
                        subtitle: "Sabah kısa gündem bildirimi",
                        value: gununOzeti,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          setState(() => gununOzeti = val);
                          prefs.setBool('gununOzeti', val);
                        },
                        textColor: yaziRengi,
                        mutedColor: altYaziRengi,
                        inputBg: inputBgColor,
                        borderColor: inputBorderColor,
                      ),
                      _buildNotificationOption(
                        title: "Akşam Özeti",
                        subtitle: "Günün kapanış özeti",
                        value: aksamOzeti,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          setState(() => aksamOzeti = val);
                          prefs.setBool('aksamOzeti', val);
                        },
                        textColor: yaziRengi,
                        mutedColor: altYaziRengi,
                        inputBg: inputBgColor,
                        borderColor: inputBorderColor,
                      ),
                      _buildNotificationOption(
                        title: "Sessiz Mod",
                        subtitle: "Bildirimleri günde 1 kez sınırlar",
                        value: sessizMod,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          setState(() => sessizMod = val);
                          prefs.setBool('sessizMod', val);
                        },
                        textColor: yaziRengi,
                        mutedColor: altYaziRengi,
                        inputBg: inputBgColor,
                        borderColor: inputBorderColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EŞLEŞME ARAYÜZÜ ---
  // Profil ve üyelik bilgilerini ana ekrandaki kart diline yakın tek blokta gösterir.
  Widget _buildProfileCard(
    TextStyle titleStyle,
    TextStyle labelStyle,
    Color textColor,
    Color mutedColor,
    Color cardBg,
    Color borderColor,
    Color shadowColor,
    Color buttonBg,
  ) {
    final displayName = currentUser?.displayName?.trim();
    final hasUser = currentUser != null;
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName.characters.first.toUpperCase()
        : 'Ö';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF9EC8ED).withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: GoogleFonts.kadwa(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName?.isNotEmpty == true
                          ? displayName!
                          : hasUser
                          ? 'Kullanıcı'
                          : 'Misafir',
                      style: titleStyle.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentUser?.email ?? 'Giriş yapılmadı',
                      style: labelStyle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9EC8ED).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: mutedColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Ücretsiz Deneme",
                      style: GoogleFonts.kadwa(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Detaylar",
                  style: GoogleFonts.kadwa(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),
          // Profil aksiyonunu kart icinde dengeli kalmasi icin tek satirda ortalar.
          Center(
            child: TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                hasUser ? "Çıkış Yap" : "Giriş Yap",
                style: GoogleFonts.kadwa(
                  color: hasUser ? Colors.red : textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Görünüm ve bildirimler gibi ayar grupları için ortak kart kabuğu.
  Widget _buildSettingsCard({
    required String title,
    required TextStyle titleStyle,
    required Color cardBg,
    required Color borderColor,
    required Color shadowColor,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: titleStyle.copyWith(fontSize: 22)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // Bildirim tercihlerini daha okunabilir, tema uyumlu kompakt satirlar olarak gosterir.
  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kadwa(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.kadwa(
                    color: mutedColor,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDarkMode
                ? Colors.white
                : const Color(0xFF0A2342),
            activeTrackColor: const Color(0xFF9EC8ED).withValues(alpha: 0.55),
            inactiveThumbColor: isDarkMode ? Colors.grey[500] : Colors.white,
            inactiveTrackColor: isDarkMode
                ? Colors.grey[800]
                : const Color(0xFFE9EEF4),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegment({
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color cardBg,
  }) {
    const double outerPadding = 4;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selectedWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                left: isDark ? selectedWidth : 0,
                top: 0,
                bottom: 0,
                width: selectedWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildThemeSegmentItem(
                    label: "Açık",
                    selected: !isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    onTap: () => _updateTheme(false),
                  ),
                  _buildThemeSegmentItem(
                    label: "Koyu",
                    selected: isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    onTap: () => _updateTheme(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSegmentItem({
    required String label,
    required bool selected,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF9EC8ED).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF9EC8ED).withValues(alpha: 0.05),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              style: GoogleFonts.kadwa(
                color: selected ? textColor : mutedColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
              child: Center(child: Text(label, textAlign: TextAlign.center)),
            ),
          ),
        ),
      ),
    );
  }

  // Eşleşme kodu oluşturma ve partner kodu girme arayüzünü yönetir.
  Widget _buildPairingSection(
    TextStyle titleStyle,
    TextStyle bodyStyle,
    TextStyle labelStyle,
    Color btnColor,
    Color inputBg,
    Color inputBorder,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.grey.withValues(alpha: 0.28);

    if (currentUser == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: inputBorder),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Eşleşme", style: titleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              "Partner eşleşmesi için hesabına giriş yapman gerekiyor.",
              style: labelStyle.copyWith(fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 14),
            _buildOptionButton(
              "Giriş Yap",
              _signOut,
              inputBg,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: inputBorder),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Eşleşme", style: titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            "Partnerinle durum paylaşmak için tek seferlik eşleşme yap.",
            style: labelStyle.copyWith(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (_isPairingLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: btnColor)),
            ),
          if (!_isPairingLoading && _pairedWith != null)
            _buildPairedPartnerPanel(
              _pairedWith!,
              titleStyle,
              bodyStyle,
              labelStyle,
              btnColor,
              inputBg,
              inputBorder,
            ),
          if (!_isPairingLoading && _pairedWith == null) ...[
            _buildUnpairedPartnerPanel(
              titleStyle,
              bodyStyle,
              labelStyle,
              btnColor,
              inputBg,
              inputBorder,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildUnpairedPartnerPanel(
    TextStyle titleStyle,
    TextStyle bodyStyle,
    TextStyle labelStyle,
    Color btnColor,
    Color inputBg,
    Color inputBorder,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Paylaşılacak kod",
                      style: labelStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      _generatedCode ?? "Henüz yok",
                      style: titleStyle.copyWith(
                        fontSize: _generatedCode == null ? 17 : 23,
                        letterSpacing: _generatedCode == null ? 0 : 3,
                        color: _generatedCode == null
                            ? labelStyle.color
                            : const Color(0xFF1F91DC),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _generatedCode == null ? "Kod oluştur" : "Kodu yenile",
                onPressed: _generatePairCode,
                icon: Icon(
                  _generatedCode == null ? Icons.add : Icons.refresh,
                  color: btnColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pairCodeController,
          style: bodyStyle.copyWith(letterSpacing: 1.2),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: "Eşinin kodu",
            labelStyle: labelStyle,
            prefixIcon: Icon(Icons.key_outlined, color: labelStyle.color),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: btnColor, width: 2),
            ),
            suffixIcon: IconButton(
              tooltip: "Eşleş",
              icon: Icon(Icons.arrow_forward_ios, color: btnColor, size: 18),
              onPressed: _enterPairCode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPairedPartnerPanel(
    String partnerUid,
    TextStyle titleStyle,
    TextStyle bodyStyle,
    TextStyle labelStyle,
    Color btnColor,
    Color inputBg,
    Color inputBorder,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final partnerName = _partnerNickname?.isNotEmpty == true
            ? _partnerNickname!
            : (data?['displayName'] as String?)?.trim();
        final displayName = partnerName?.isNotEmpty == true
            ? partnerName!
            : 'Partner';
        final statusIcon = data?['statusIcon'] as String? ?? '•';
        final statusText = data?['statusText'] as String? ?? 'Durum yok';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9EC8ED).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      statusIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: titleStyle.copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          statusText,
                          style: labelStyle.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _partnerNicknameController,
                style: bodyStyle.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Takma ad",
                  labelStyle: labelStyle,
                  hintText: "Örn: Canım",
                  hintStyle: labelStyle.copyWith(fontSize: 13),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: labelStyle.color,
                  ),
                  suffixIcon: IconButton(
                    tooltip: "Kaydet",
                    icon: Icon(Icons.check, color: btnColor),
                    onPressed: _savePartnerNickname,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF222222)
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: btnColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _confirmUnpair,
                  child: Text(
                    "Eşleşmeyi bitir",
                    style: GoogleFonts.kadwa(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    String text,
    VoidCallback onPressed,
    Color bg,
    Color textCol,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.kadwa(
                  fontWeight: FontWeight.bold,
                  color: textCol,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textCol),
          ],
        ),
      ),
    );
  }
}
