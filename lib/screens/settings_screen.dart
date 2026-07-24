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
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // Bu state sınıfı, ayarlar ekranındaki kullanıcı bilgisi, tema durumu,
  // bildirim tercihleri ve eşleşme akışını yönetir.
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

  bool _isPairingLoading = false;
  // Scroll pozisyonunu takip etmek için controller
  final ScrollController _scrollController = ScrollController();
  // Sayfa kaydırıldı mı kontrolü (10px üzeri = true)
  bool _isScrolled = false;
  @override
  void initState() {
    super.initState();
    // Sayfa açılırken daha önce kaydedilmiş ayarlar ve mevcut eşleşme bilgileri yüklenir.
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

    _scrollController
        .dispose(); // Memory leak önlemek için controller'ı temizle
    super.dispose();
  }

  // SharedPreferences'ten daha önce kaydedilmiş bildirim ayarlarını okuyup ekrana uygular.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gununOzeti = prefs.getBool('gununOzeti') ?? true;
      aksamOzeti = prefs.getBool('aksamOzeti') ?? true;
      sessizMod = prefs.getBool('sessizMod') ?? false;
    });
  }

  // Kullanıcının Firestore'da daha önce oluşturduğu eşleşme kodu, eşleştirildiği partner ve takma ad bilgisini kontrol eder.
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
      });
    }
  }

  // Tema seçimini günceller ve seçimi SharedPreferences'e kaydeder.
  Future<void> _updateTheme(bool isDarkTheme) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      themeNotifier.value = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
    });
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  // Firebase'den kullanıcıyı çıkış yaptırır ve giriş ekranına geri döndürür.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  // === 1. KOD OLUŞTURMA (Benim İçin) ===
  // Kullanıcı için yeni bir 6 haneli eşleşme kodu üretir, Firestore'a kaydeder ve duruma uygular.
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
      debugPrint("Hata: $e");
      setState(() => _isPairingLoading = false);
    }
  }

  // Oluşturulmuş eşleşme kodunu panoya kopyalar ve kullanıcıya bilgi verir.
  Future<void> _copyPairCode() async {
    final code = _generatedCode;
    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    AppFeedback.show(
      context,
      "Eşleşme kodu kopyalandı.",
      type: AppFeedbackType.success,
    );
  }

  // === 2. KOD GİRME VE EŞLEŞME (Eşim İçin) ===
  // Kullanıcının girdiği eşleşme kodunu kontrol eder, doğruysa partner ile eşleştirir.
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
      if (!mounted) return;

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
      if (!mounted) return;

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
      debugPrint("Hata: $e");
      if (!mounted) return;

      AppFeedback.show(
        context,
        "Eşleşme tamamlanamadı. Lütfen tekrar dene.",
        type: AppFeedbackType.error,
      );
      setState(() => _isPairingLoading = false);
    }
  }

  // Partner takma adını kaydeder veya siler, ardından durumu günceller.
  Future<void> _savePartnerNickname(
    String nickname, {
    required String successMessage,
  }) async {
    if (currentUser == null) return;

    final normalizedNickname = nickname.trim();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .set({
          'partnerNickname': normalizedNickname.isEmpty
              ? FieldValue.delete()
              : normalizedNickname,
        }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _partnerNickname = normalizedNickname.isEmpty ? null : normalizedNickname;
    });

    AppFeedback.show(context, successMessage, type: AppFeedbackType.success);
  }

  // Partner takma adını düzenlemek için alt sayfayı açar.
  Future<void> _showNicknameEditor({required String accountName}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (sheetContext) {
        return _NicknameEditorSheet(
          accountName: accountName,
          initialNickname: _partnerNickname ?? '',
          onSave: (nickname) async {
            final isRemoving = nickname.trim().isEmpty;
            try {
              await _savePartnerNickname(
                nickname,
                successMessage: isRemoving
                    ? 'Takma ad kaldırıldı.'
                    : 'Takma ad kaydedildi.',
              );
            } catch (_) {
              if (mounted) {
                AppFeedback.show(
                  context,
                  'Takma ad güncellenemedi. Lütfen tekrar dene.',
                  type: AppFeedbackType.error,
                );
              }
              rethrow;
            }

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        );
      },
    );
  }

  // Kullanıcıdan eşleşmeyi sonlandırma onayı alır.
  Future<void> _confirmUnpair() async {
    if (currentUser == null || _pairedWith == null) return;

    final palette = _SettingsPalette.of(context);
    final shouldUnpair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border),
        ),
        title: Text(
          'Eşleşmeyi bitir?',
          style: GoogleFonts.inter(
            color: palette.text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        content: Text(
          'Partner durumunu artık göremezsin. Daha sonra yeni bir kodla tekrar eşleşebilirsin.',
          style: GoogleFonts.inter(
            color: palette.muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: palette.muted),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: palette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Bitir',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldUnpair != true) return;
    await _unpairPartner();
  }

  // Mevcut eşleşmeyi kaldırır, hem kendi hem partnerin Firestore verilerini temizler.
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
    final palette = _SettingsPalette.of(context);
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: palette.isDark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
    );

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            toolbarHeight: 62,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: overlayStyle,
            centerTitle: true,
            leadingWidth: 66,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: IconButton(
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: palette.text,
                style: IconButton.styleFrom(
                  backgroundColor: palette.surface.withValues(alpha: 0.84),
                  side: BorderSide(color: palette.border),
                  fixedSize: const Size.square(40),
                  shape: const CircleBorder(),
                ),
              ),
            ),
            title: AnimatedOpacity(
              opacity: _isScrolled ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Text(
                'Ayarlar',
                style: GoogleFonts.inter(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  color: _isScrolled
                      ? palette.scaffold.withValues(alpha: 0.88)
                      : palette.scaffold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    MediaQuery.paddingOf(context).bottom + 36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Ayarlar',
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildProfileCard(palette),
                      const SizedBox(height: 8),
                      _buildPairingSection(palette),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        title: 'Görünüm',
                        subtitle: 'Uygulamanın görünümünü seç.',
                        palette: palette,
                        children: [
                          _buildThemeSegment(isDark: isDark, palette: palette),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        title: 'Bildirimler',
                        subtitle:
                            'Gün içinde ne zaman haber almak istediğini belirle.',
                        palette: palette,
                        children: [
                          _buildNotificationOption(
                            icon: Icons.wb_sunny_outlined,
                            title: 'Günün Özeti',
                            subtitle: 'Sabah kısa gündem bildirimi',
                            value: gununOzeti,
                            onChanged: (value) =>
                                _saveNotificationSetting('gununOzeti', value),
                            palette: palette,
                          ),
                          _buildSettingsDivider(palette, indent: 50),
                          _buildNotificationOption(
                            icon: Icons.nights_stay_outlined,
                            title: 'Akşam Özeti',
                            subtitle: 'Günün kapanış özeti',
                            value: aksamOzeti,
                            onChanged: (value) =>
                                _saveNotificationSetting('aksamOzeti', value),
                            palette: palette,
                          ),
                          _buildSettingsDivider(palette, indent: 50),
                          _buildNotificationOption(
                            icon: Icons.notifications_off_outlined,
                            title: 'Sessiz Mod',
                            subtitle: 'Bildirimleri günde 1 kez sınırlar',
                            value: sessizMod,
                            onChanged: (value) =>
                                _saveNotificationSetting('sessizMod', value),
                            palette: palette,
                          ),
                        ],
                      ),
                      if (currentUser != null) ...[
                        const SizedBox(height: 20),
                        _buildSignOutButton(palette),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kullanıcının bildirim tercihlerini kaydeder ve ekranı günceller.
  Future<void> _saveNotificationSetting(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'gununOzeti':
          gununOzeti = value;
        case 'aksamOzeti':
          aksamOzeti = value;
        case 'sessizMod':
          sessizMod = value;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Profil kartı: kullanıcı adını, e-postayı ve üyelik durumunu gösterir.
  Widget _buildProfileCard(_SettingsPalette palette) {
    final displayName = currentUser?.displayName?.trim();
    final hasUser = currentUser != null;
    final visibleName = displayName?.isNotEmpty == true
        ? displayName!
        : hasUser
        ? 'Kullanıcı'
        : 'Misafir';
    final initial = visibleName.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _settingsCardDecoration(palette),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.controlSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visibleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? 'Giriş yapılmadı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.controlSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 14,
                      color: palette.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Ücretsiz',
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Eşleşme bölümünün durumuna göre farklı görünümler üretir: bekliyor, bağlı veya yükleniyor.
  Widget _buildPairingSection(_SettingsPalette palette) {
    if (currentUser == null) {
      return _buildSettingsCard(
        title: 'Eşleşme',
        subtitle: 'Partner özellikleri için hesabına giriş yap.',
        headerTrailing: _buildPairingStatusBadge(
          label: 'Giriş gerekli',
          palette: palette,
        ),
        palette: palette,
        children: [
          _buildPrimaryButton(
            label: 'Giriş Yap',
            icon: Icons.login_rounded,
            onPressed: _signOut,
            palette: palette,
          ),
        ],
      );
    }

    final isPaired = _pairedWith != null;
    final stateKey = _isPairingLoading
        ? 'loading'
        : isPaired
        ? 'paired'
        : 'waiting';
    final Widget stateContent;
    if (_isPairingLoading) {
      stateContent = _buildPairingProgress(palette);
    } else if (isPaired) {
      stateContent = _buildPairedPartnerPanel(_pairedWith!, palette);
    } else {
      stateContent = _buildUnpairedPartnerPanel(palette);
    }

    return _buildSettingsCard(
      title: 'Eşleşme',
      subtitle: isPaired
          ? 'Partner bağlantını ve görünen adı yönet.'
          : 'Tek kullanımlık kodla partnerine bağlan.',
      headerTrailing: _buildPairingStatusBadge(
        label: _isPairingLoading
            ? 'İşleniyor'
            : isPaired
            ? 'Bağlı'
            : 'Bekliyor',
        active: isPaired,
        loading: _isPairingLoading,
        palette: palette,
      ),
      palette: palette,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          reverseDuration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey(stateKey), child: stateContent),
        ),
      ],
    );
  }

  Widget _buildPairingStatusBadge({
    required String label,
    required _SettingsPalette palette,
    bool active = false,
    bool loading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox.square(
              dimension: 9,
              child: CircularProgressIndicator(
                color: palette.muted,
                strokeWidth: 1.5,
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? palette.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? palette.accent : palette.muted,
                  width: 1.2,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: active ? palette.text : palette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingProgress(_SettingsPalette palette) {
    return Container(
      key: const ValueKey('pairing-progress'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: palette.controlSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 19,
            child: CircularProgressIndicator(
              color: palette.accent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bağlantı hazırlanıyor…',
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpairedPartnerPanel(_SettingsPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
          decoration: BoxDecoration(
            color: palette.controlSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.key_rounded, size: 15, color: palette.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tek kullanımlık kodun',
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _generatedCode ?? '------',
                  key: ValueKey(_generatedCode),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    color: _generatedCode == null
                        ? palette.muted
                        : palette.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedCode == null
                    ? 'Partnerinle paylaşmak için yeni bir kod oluştur.'
                    : 'Kod yalnızca bir eşleşme için geçerlidir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: palette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _generatedCode == null
                    ? SizedBox(
                        key: const ValueKey('generate-code'),
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: _generatePairCode,
                          icon: const Icon(Icons.add_link_rounded, size: 17),
                          label: const Text('Kod oluştur'),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.onAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            textStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('code-actions'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPairingToolButton(
                            icon: Icons.content_copy_rounded,
                            tooltip: 'Kodu kopyala',
                            onPressed: _copyPairCode,
                            palette: palette,
                          ),
                          const SizedBox(width: 9),
                          _buildPairingToolButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Kodu yenile',
                            onPressed: _generatePairCode,
                            palette: palette,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.link_rounded, size: 16, color: palette.text),
            const SizedBox(width: 7),
            Text(
              'Partnerinin kodu',
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pairCodeController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _enterPairCode(),
          style: GoogleFonts.robotoMono(
            color: palette.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          decoration: _settingsInputDecoration(
            hintText: '6 haneli kodu gir',
            prefixIcon: Icons.dialpad_rounded,
            palette: palette,
            suffix: IconButton(
              tooltip: 'Eşleş',
              onPressed: _enterPairCode,
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              color: palette.onAccent,
              style: IconButton.styleFrom(
                backgroundColor: palette.accent,
                fixedSize: const Size.square(36),
                shape: const CircleBorder(),
              ),
            ),
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _buildPairingToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required _SettingsPalette palette,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: palette.text,
      style: IconButton.styleFrom(
        backgroundColor: palette.surface,
        side: BorderSide(color: palette.border),
        fixedSize: const Size.square(38),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildPairedPartnerPanel(String partnerUid, _SettingsPalette palette) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final accountName = (data?['displayName'] as String?)?.trim();
        final displayName = _partnerNickname?.isNotEmpty == true
            ? _partnerNickname!
            : accountName?.isNotEmpty == true
            ? accountName!
            : 'Partner';
        final rawStatus = (data?['statusText'] as String?)?.trim();
        final statusText = snapshot.connectionState == ConnectionState.waiting
            ? 'Durum alınıyor…'
            : rawStatus?.isNotEmpty == true
            ? rawStatus!
            : 'Henüz durum paylaşmadı';
        final initial = displayName.characters.first.toUpperCase();

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.controlSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.selectedSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: palette.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.15,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.link_rounded, size: 19, color: palette.muted),
                ],
              ),
            ),
            const SizedBox(height: 11),
            _buildNicknameSummary(
              palette,
              accountName: accountName?.isNotEmpty == true
                  ? accountName!
                  : 'Partner',
            ),
            const SizedBox(height: 7),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 3),
            Center(
              child: TextButton.icon(
                onPressed: _confirmUnpair,
                icon: const Icon(Icons.link_off_rounded, size: 16),
                label: const Text('Eşleşmeyi bitir'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.danger,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Partner için takma ad bilgisini gösterir ve düzenleme ekranını açar.
  Widget _buildNicknameSummary(
    _SettingsPalette palette, {
    required String accountName,
  }) {
    final nickname = _partnerNickname?.trim();
    final hasNickname = nickname?.isNotEmpty == true;

    return Tooltip(
      message: 'Takma adı düzenle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNicknameEditor(accountName: accountName),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              color: palette.controlSurface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.selectedSurface.withValues(alpha: 0.86),
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Takma ad',
                        style: GoogleFonts.inter(
                          color: palette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasNickname ? nickname! : 'Takma ad ekle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hesap adı: $accountName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: palette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.selectedSurface.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Her ayar bölümünü tek bir kart yapısı içinde düzenler.
  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required _SettingsPalette palette,
    required List<Widget> children,
    Widget? headerTrailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: _settingsCardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 10),
                headerTrailing,
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  BoxDecoration _settingsCardDecoration(_SettingsPalette palette) {
    return BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: palette.border),
      boxShadow: [
        BoxShadow(
          color: palette.shadow,
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  InputDecoration _settingsInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required _SettingsPalette palette,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: palette.border),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: palette.muted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      prefixIcon: Icon(prefixIcon, size: 19, color: palette.muted),
      suffixIcon: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 6), child: suffix),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 44),
      filled: true,
      fillColor: palette.controlSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: palette.accent, width: 1.4),
      ),
    );
  }

  // Kullanıcıyı uygulamadan çıkış yaptıran butonu oluşturur.
  Widget _buildSignOutButton(_SettingsPalette palette) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Çıkış Yap'),
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.danger.withValues(alpha: 0.08),
          foregroundColor: palette.danger,
          side: BorderSide(color: palette.danger.withValues(alpha: 0.32)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required _SettingsPalette palette,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // Tema seçimi için açık/koyu modu değiştiren segmentli kontrolü oluşturur.
  Widget _buildThemeSegment({
    required bool isDark,
    required _SettingsPalette palette,
  }) {
    return SizedBox(
      height: 46,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const inset = 4.0;
          final selectedWidth = (constraints.maxWidth - inset * 2) / 2;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: palette.controlSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: palette.border),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: isDark ? inset + selectedWidth : inset,
                  top: inset,
                  bottom: inset,
                  width: selectedWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.selectedSurface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: palette.border),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow,
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
                      label: 'Açık',
                      selected: !isDark,
                      palette: palette,
                      onTap: () => _updateTheme(false),
                    ),
                    _buildThemeSegmentItem(
                      label: 'Koyu',
                      selected: isDark,
                      palette: palette,
                      onTap: () => _updateTheme(true),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeSegmentItem({
    required String label,
    required bool selected,
    required _SettingsPalette palette,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: palette.accent.withValues(alpha: 0.06),
          highlightColor: palette.accent.withValues(alpha: 0.035),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: GoogleFonts.inter(
                color: selected ? palette.text : palette.muted,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  // Her bir bildirim seçeneği için düzenli bir satır widget'ı oluşturur.
  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required _SettingsPalette palette,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        splashColor: palette.accent.withValues(alpha: 0.05),
        highlightColor: palette.accent.withValues(alpha: 0.025),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.controlSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Icon(icon, size: 18, color: palette.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: palette.onAccent,
                activeTrackColor: palette.accent,
                inactiveThumbColor: palette.isDark
                    ? const Color(0xFF8E8E93)
                    : Colors.white,
                inactiveTrackColor: palette.controlSurface,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: WidgetStatePropertyAll(
                  palette.accent.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsDivider(_SettingsPalette palette, {double indent = 0}) {
    return Divider(
      color: palette.border,
      height: 1,
      thickness: 1,
      indent: indent,
    );
  }
}

// Partner takma adını değiştirmek için kullanılan alt sayfa arayüzü.
class _NicknameEditorSheet extends StatefulWidget {
  const _NicknameEditorSheet({
    required this.accountName,
    required this.initialNickname,
    required this.onSave,
  });

  final String accountName;
  final String initialNickname;
  final Future<void> Function(String nickname) onSave;

  @override
  State<_NicknameEditorSheet> createState() => _NicknameEditorSheetState();
}

class _NicknameEditorSheetState extends State<_NicknameEditorSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  String get _normalizedNickname => _controller.text.trim();

  String get _previewName {
    return _normalizedNickname.isEmpty
        ? widget.accountName
        : _normalizedNickname;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit({bool remove = false}) async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await widget.onSave(remove ? '' : _normalizedNickname);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final previewName = _previewName;
    final previewInitial = previewName.characters.first.toUpperCase();
    final hasExistingNickname = widget.initialNickname.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: palette.surface.withValues(
                    alpha: palette.isDark ? 0.92 : 0.88,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(color: palette.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: palette.isDark ? 0.34 : 0.14,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.muted.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Takma ad',
                                  style: GoogleFonts.inter(
                                    color: palette.text,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Partnerini uygulamada nasıl görmek istersin?',
                                  style: GoogleFonts.inter(
                                    color: palette.muted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Kapat',
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 19),
                            color: palette.text,
                            style: IconButton.styleFrom(
                              backgroundColor: palette.controlSurface
                                  .withValues(alpha: 0.78),
                              disabledForegroundColor: palette.muted,
                              side: BorderSide(color: palette.border),
                              fixedSize: const Size.square(38),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.controlSurface.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Kart önizlemesi',
                                  style: GoogleFonts.inter(
                                    color: palette.muted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: palette.muted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: palette.selectedSurface.withValues(
                                      alpha: 0.88,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: palette.border),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 160),
                                    child: Text(
                                      previewInitial,
                                      key: ValueKey(previewInitial),
                                      style: GoogleFonts.inter(
                                        color: palette.text,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 170,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                        child: Text(
                                          previewName,
                                          key: ValueKey(previewName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: palette.text,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _normalizedNickname.isEmpty
                                            ? 'Varsayılan hesap adı'
                                            : 'Hesap adı: ${widget.accountName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: palette.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Takma ad',
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        enabled: !_isSaving,
                        maxLength: 24,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: [LengthLimitingTextInputFormatter(24)],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Örn: Canım',
                          hintStyle: GoogleFonts.inter(
                            color: palette.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            size: 19,
                            color: palette.muted,
                          ),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Temizle',
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                  ),
                                  color: palette.muted,
                                ),
                          counterText: '',
                          filled: true,
                          fillColor: palette.controlSurface.withValues(
                            alpha: 0.78,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: palette.accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_controller.text.characters.length}/24',
                          style: GoogleFonts.inter(
                            color: palette.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.onAccent,
                            disabledBackgroundColor: palette.accent.withValues(
                              alpha: 0.72,
                            ),
                            disabledForegroundColor: palette.onAccent
                                .withValues(alpha: 0.82),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: _isSaving
                                ? SizedBox(
                                    key: const ValueKey('nickname-saving'),
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.onAccent,
                                    ),
                                  )
                                : const Row(
                                    key: ValueKey('nickname-save'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, size: 18),
                                      SizedBox(width: 7),
                                      Text('Kaydet'),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      if (hasExistingNickname) ...[
                        const SizedBox(height: 5),
                        Center(
                          child: TextButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _submit(remove: true),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('Takma adı kaldır'),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.danger,
                              disabledForegroundColor: palette.muted,
                              textStyle: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Ayarlar ekranındaki renk paletini tek yerde tutan yardımcı sınıf.
class _SettingsPalette {
  const _SettingsPalette({
    required this.isDark,
    required this.scaffold,
    required this.surface,
    required this.controlSurface,
    required this.selectedSurface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.shadow,
    required this.danger,
  });

  factory _SettingsPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsPalette(
      isDark: isDark,
      scaffold: Theme.of(context).scaffoldBackgroundColor,
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      controlSurface: isDark
          ? const Color(0xFF2A2A2C)
          : const Color(0xFFF4F4F6),
      selectedSurface: isDark ? const Color(0xFF3A3A3C) : Colors.white,
      text: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      muted: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
      border: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFFE7E7EA),
      accent: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      onAccent: isDark ? const Color(0xFF111114) : Colors.white,
      shadow: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
      danger: isDark ? const Color(0xFFFF7A7A) : const Color(0xFFC7353D),
    );
  }

  final bool isDark;
  final Color scaffold;
  final Color surface;
  final Color controlSurface;
  final Color selectedSurface;
  final Color text;
  final Color muted;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color shadow;
  final Color danger;
}
