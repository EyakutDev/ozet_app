import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- YENİ: Kullanıcıyı bulmak için
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- YENİ: Bildirim Token'ı için
import 'dart:ui' as ui;
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/screens/daily_score_screen.dart';
import 'package:ozet_app/screens/daily_score_history_screen.dart';
import 'package:ozet_app/screens/settings_screen.dart';
import 'package:ozet_app/services/daily_score_storage.dart';
import 'package:ozet_app/services/news_read_storage.dart';
import 'package:ozet_app/services/news_feed_service.dart';
import 'package:ozet_app/widgets/paginated_news_feed.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:ozet_app/widgets/partner_widget.dart';
import 'package:ozet_app/widgets/app_feedback.dart';
import 'package:ozet_app/widgets/daily_cards_widget.dart';
import 'package:ozet_app/widgets/liquid_glass_app_bar.dart';
import 'package:ozet_app/screens/news_webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Haberler cursor tabanli sayfalar halinde yuklenir.
  final NewsFeedService _newsFeedService = NewsFeedService();
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Sayfanın kaydırılmasını kontrol eden mekanizma
  final ScrollController _scrollController = ScrollController();
  final DailyScoreStorage _dailyScoreStorage = DailyScoreStorage();
  final NewsReadStorage _newsReadStorage = NewsReadStorage();

  DailyScoreEntry? _todayScore;
  bool _isDailyScoreLoading = true;
  Set<String> _readNewsIds = <String>{};

  // Sayfa aşağı kaydırıldı mı? (Blur efekti için kullanılır)
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodayScore();
    _loadReadNewsIds();

    // === 1. BİLDİRİM TOKEN'INI KAYDET ===
    // Uygulama açılınca bu cihazın kimliğini veritabanına yazarız.
    // Böylece partnerin sana bildirim atabilir.
    _saveDeviceToken();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(_storeDeviceToken);

    // === 2. SCROLL DİNLEYİCİSİ ===
    // Sayfa kaydırıldıkça AppBar'ın bulanıklaşmasını sağlar
    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTodayScore();
    }
  }

  Future<void> _loadTodayScore() async {
    final entry = await _dailyScoreStorage.getForDate(DateTime.now());
    if (!mounted) return;

    setState(() {
      _todayScore = entry;
      _isDailyScoreLoading = false;
    });
  }

  Future<void> _loadReadNewsIds() async {
    try {
      final storedIds = await _newsReadStorage.getReadIds();
      if (!mounted) return;

      // Yukleme surerken acilan bir haber varsa onun durumunu kaybetmeyiz.
      setState(() => _readNewsIds = {...storedIds, ..._readNewsIds});
    } on Object {
      // Yerel okundu verisi haber akisinin acilmasini engellememeli.
    }
  }

  void _markNewsAsRead(String newsId) {
    if (_readNewsIds.contains(newsId)) return;

    setState(() => _readNewsIds = {..._readNewsIds, newsId});
    unawaited(_persistReadNews(newsId));
  }

  Future<void> _persistReadNews(String newsId) async {
    try {
      await _newsReadStorage.markRead(newsId);
    } on Object {
      // Oturumdaki gorsel durum korunur; kalici yazma sonraki okumada yenilenir.
    }
  }

  Future<void> _openDailyScore() async {
    final entry = await Navigator.of(context).push<DailyScoreEntry>(
      MaterialPageRoute(
        builder: (_) => DailyScoreScreen(initialEntry: _todayScore),
      ),
    );
    if (entry == null || !mounted) return;

    try {
      await _dailyScoreStorage.save(entry);
      if (!mounted) return;
      setState(() => _todayScore = entry);
      AppFeedback.show(
        context,
        'Gün kartın oluşturuldu.',
        type: AppFeedbackType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.show(
        context,
        'Gün kartı kaydedilemedi. Tekrar deneyebilirsin.',
        type: AppFeedbackType.error,
      );
    }
  }

  void _openDailyScoreHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DailyScoreHistoryScreen()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _saveDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _storeDeviceToken(token);
      }
    } catch (_) {
      // Token sonraki uygulama açılışında veya yenilendiğinde tekrar kaydedilir.
    }
  }

  Future<void> _storeDeviceToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('user_private')
        .doc(user.uid)
        .set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _openSourceUrl(String sourceUrl, String title) {
    final uri = Uri.tryParse(sourceUrl.trim());
    final isWebUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isWebUrl) {
      AppFeedback.show(
        context,
        'Kaynak bağlantısı geçersiz.',
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsWebViewScreen(url: uri.toString(), title: title),
      ),
    );
  }

  Widget _buildHomeBrand(bool isDark) {
    final logo = Image.asset(
      'assets/logo_ozet.png',
      height: 104,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Özet',
    );

    if (!isDark) return logo;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: logo,
    );
  }

  Widget _buildHomeTopBar({required bool isDark, required Color textColor}) {
    return LiquidGlassSliverAppBar(
      isDark: isDark,
      isScrolled: _isScrolled,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: LiquidGlassIconButton(
        isDark: isDark,
        foregroundColor: textColor,
        icon: Icons.settings_outlined,
        tooltip: 'Ayarlar',
        onPressed: _openSettings,
      ),
      title: _buildHomeBrand(isDark),
    );
  }

  @override
  void dispose() {
    // Sayfa kapanırsa memory leak olmasın diye controller'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    _tokenRefreshSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // === TEMA VE RENK AYARLARI ===
    // Telefonun karanlık modda mı?
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Renk paleti (Karanlık/Aydınlık moda göre değişir)
    final Color yaziRengi = isDark ? AppThemePalette.darkText : Colors.black;
    final Color kartRengi = isDark ? AppThemePalette.darkSurface : Colors.white;
    final Color altYaziRengi = isDark
        ? AppThemePalette.darkMuted
        : Colors.grey[700]!;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // === ÜST BAR (APP BAR) ===
          _buildHomeTopBar(isDark: isDark, textColor: yaziRengi),
          // === ANA İÇERİK ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 1),
                  Text(
                    " Bugün ne oldu?",
                    style: GoogleFonts.kadwa(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: yaziRengi,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1. Partner ve Günlük Kartlar
                  SizedBox(
                    height: 164,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildLiveWidgets(
                        kartRengi,
                        yaziRengi,
                        altYaziRengi,
                      ),
                    ),
                  ),

                  const SizedBox(height: 0.01), // Ayrım boşluğu
                  // 2. Haber Akışı
                  _buildNewsFeed(kartRengi, yaziRengi, altYaziRengi),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Günlük değerlendirme ve partner alanını ana akışın üzerinde tutar.
  Widget _buildLiveWidgets(
    Color kartRengi,
    Color yaziRengi,
    Color altYaziRengi,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? AppThemePalette.darkSurface.withValues(alpha: 0.64)
        : Colors.white.withValues(alpha: 0.46);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.075);
    final panelBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.12);
    final edgeHighlight = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.96);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // İki gölge katmanı camı rengini koyulaştırmadan zeminden ayırır.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 11),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.14),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: panelBorderColor),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1, -1),
                      end: const Alignment(1, 1),
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.035),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.70),
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.30),
                            ],
                      stops: const [0, 0.28, 0.72, 1],
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PartnerWidget(cardColor: panelColor, embedded: true),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                    color: dividerColor,
                  ),
                  Expanded(
                    child: DailyCardsWidget(
                      entry: _todayScore,
                      isLoading: _isDailyScoreLoading,
                      onDailyScoreTap: _openDailyScore,
                      onHistoryTap: _openDailyScoreHistory,
                      cardColor: panelColor,
                      textColor: yaziRengi,
                      mutedColor: altYaziRengi,
                      embedded: true,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 0.8,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: edgeHighlight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Haber Listesini Oluşturur ---
  Widget _buildNewsFeed(Color kartRengi, Color yaziRengi, Color altYaziRengi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.17)
        : Colors.black.withValues(alpha: 0.14);

    return PaginatedNewsFeed(
      service: _newsFeedService,
      isVisible: _isVisibleNews,
      mutedColor: altYaziRengi,
      dividerColor: dividerColor,
      scrollController: _scrollController,
      itemBuilder: (context, document) {
        final data = document.data();
        final newsId = document.id;
        return _buildNewsListItem(
          newsId: newsId,
          isRead: _readNewsIds.contains(newsId),
          title: _textField(data, 'title'),
          summary: _textField(data, 'summary'),
          detail: _textField(data, 'detail'),
          source: _textField(data, 'source', fallback: 'Ozet App'),
          category: _textField(data, 'category'),
          sourceUrl: _textField(data, 'sourceUrl'),
          createdAt: data['publishedAt'] ?? data['createdAt'],
          kartRengi: kartRengi,
          yaziRengi: yaziRengi,
          altYaziRengi: altYaziRengi,
        );
      },
    );
  }

  String _textField(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value is! String) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  // RSS taslaklari ve admin onayi bekleyen haberler mobil akista gorunmez.
  bool _isVisibleNews(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final published = data['published'];
    final status = (data['status'] as String?)?.trim().toLowerCase();

    if (published == false) return false;
    if (status == 'draft' || status == 'rejected') return false;
    return published == true || status == 'published' || status == null;
  }

  Color _newsAccentBackground(BuildContext context) {
    return Colors.transparent;
  }

  Color _newsAccentForeground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF222222);
  }

  Color _newsAccentBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.14);
  }

  Widget _buildNewsMetaChip(String label) {
    final backgroundColor = _newsAccentBackground(context);
    final foregroundColor = _newsAccentForeground(context);
    final borderColor = _newsAccentBorder(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.kadwa(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }

  // --- Tekil Haber Kartı Tasarımı ---
  // Admin panelinden gelen mevcut haber alanlarını bozmadan modern kart olarak çizer.
  /// Admin panelinden gelen alanları değiştirmeden editoryal liste satırı çizer.
  Widget _buildNewsListItem({
    required String newsId,
    required bool isRead,
    required String title,
    required String summary,
    required String detail,
    required String source,
    required String category,
    required String sourceUrl,
    required dynamic createdAt,
    required Color kartRengi,
    required Color yaziRengi,
    required Color altYaziRengi,
  }) {
    final formattedDate = _formatCreatedAt(createdAt);
    final titleColor = isRead
        ? Color.lerp(yaziRengi, kartRengi, 0.38)!
        : yaziRengi;
    final summaryColor = isRead
        ? Color.lerp(altYaziRengi, kartRengi, 0.18)!
        : altYaziRengi;

    return Semantics(
      button: true,
      label: isRead ? '$title haberini aç' : 'Okunmamış: $title haberini aç',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: yaziRengi.withValues(alpha: 0.06),
          highlightColor: yaziRengi.withValues(alpha: 0.035),
          onTap: () {
            _markNewsAsRead(newsId);
            _showModernDetailModal(
              title,
              detail,
              summary,
              source,
              sourceUrl,
              kartRengi,
              yaziRengi,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (category.isNotEmpty) ...[
                      _buildNewsMetaChip(category),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: _buildNewsMetaChip(source)),
                    if (formattedDate != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: GoogleFonts.kadwa(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: altYaziRengi,
                        ),
                      ),
                    ],
                    if (!isRead) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: yaziRengi,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.kadwa(
                    fontSize: 18,
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: GoogleFonts.kadwa(
                      fontSize: 14,
                      color: summaryColor,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Firestore Timestamp, DateTime veya string tarih değerini kısa kart tarihine çevirir.
  String? _formatCreatedAt(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return null;

    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  // Haber detayını eski merkez dialog mekanizmasıyla, yeni kart tasarımıyla gösterir.
  void _showModernDetailModal(
    String title,
    String detail,
    String summary,
    String source,
    String sourceUrl,
    Color kartRengi,
    Color yaziRengi,
  ) {
    final bodyText = detail.trim().isNotEmpty ? detail : summary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final accentBackground = _newsAccentBackground(context);
    final accentForeground = _newsAccentForeground(context);
    final accentMuted = mutedColor;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Detay",
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.94,
              end: 1,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.94,
                constraints: BoxConstraints(
                  maxWidth: 620,
                  maxHeight: MediaQuery.of(context).size.height * 0.74,
                ),
                decoration: BoxDecoration(
                  color: kartRengi,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 14, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentBackground,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    source,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.kadwa(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accentForeground,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: GoogleFonts.kadwa(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: yaziRengi,
                                    height: 1.22,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kapat',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: mutedColor,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                      child: Divider(color: dividerColor, height: 1),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bodyText,
                              style: GoogleFonts.kadwa(
                                fontSize: 16,
                                color: yaziRengi,
                                height: 1.62,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            if (sourceUrl.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Divider(color: dividerColor, height: 1),
                              const SizedBox(height: 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _openSourceUrl(sourceUrl, title),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentBackground,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: dividerColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.open_in_new_rounded,
                                          size: 18,
                                          color: accentForeground,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'Kaynağı aç',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.kadwa(
                                              fontSize: 13,
                                              color: accentForeground,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            sourceUrl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.kadwa(
                                              fontSize: 11,
                                              color: accentMuted,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
