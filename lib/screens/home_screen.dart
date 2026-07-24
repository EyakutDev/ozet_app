import 'package:flutter/material.dart';
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
import 'package:ozet_app/widgets/partner_widget.dart';
import 'package:ozet_app/widgets/app_feedback.dart';
import 'package:ozet_app/widgets/daily_cards_widget.dart';
import 'package:ozet_app/screens/news_webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Haberleri çektiğimiz veri akışı (Canlı dinler)
  final Stream<QuerySnapshot> _newsStream = FirebaseFirestore.instance
      .collection('news')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // Sayfanın kaydırılmasını kontrol eden mekanizma
  final ScrollController _scrollController = ScrollController();
  final DailyScoreStorage _dailyScoreStorage = DailyScoreStorage();

  DailyScoreEntry? _todayScore;
  bool _isDailyScoreLoading = true;

  // Sayfa aşağı kaydırıldı mı? (Blur efekti için kullanılır)
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodayScore();

    // === 1. BİLDİRİM TOKEN'INI KAYDET ===
    // Uygulama açılınca bu cihazın kimliğini veritabanına yazarız.
    // Böylece partnerin sana bildirim atabilir.
    _saveDeviceToken();

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

  // === CİHAZ TOKEN KAYDETME FONKSİYONU ===
  Future<void> _saveDeviceToken() async {
    // 1. Bu cihazın özel bildirim adresini (Token) al
    String? token = await FirebaseMessaging.instance.getToken();

    // 2. Şu anki kullanıcıyı bul
    User? user = FirebaseAuth.instance.currentUser;

    // 3. Eğer ikisi de varsa veritabanına kaydet
    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token, // <-- Adres buraya yazılıyor
      }, SetOptions(merge: true)); // Mevcut verileri silmeden sadece bunu ekler
    }
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

  @override
  void dispose() {
    // Sayfa kapanırsa memory leak olmasın diye controller'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // === TEMA VE RENK AYARLARI ===
    // Telefonun karanlık modda mı?
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Renk paleti (Karanlık/Aydınlık moda göre değişir)
    final Color yaziRengi = isDark ? Colors.white : Colors.black;
    final Color kartRengi = isDark
        ? const Color(0xFF1E1E1E) // Koyu gri
        : Colors.white;
    final Color altYaziRengi = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final Color golgeRengi = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.5);
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // === ÜST BAR (APP BAR) ===
          SliverAppBar(
            pinned: true, // Yukarıda sabit kalır
            floating: false,
            backgroundColor: Colors.transparent, // Şeffaf başlar
            elevation: 0, // Gölge yok
            // Ayarlar İkonu
            leading: IconButton(
              icon: Icon(Icons.settings_outlined, color: yaziRengi, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),

            // Logo (Temaya göre rengi değişebilir veya filtre uygulanabilir)
            title: isDark
                ? ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset('assets/logo_ozet.png', height: 120),
                  )
                : Image.asset('assets/logo_ozet.png', height: 120),
            centerTitle: true,
            actions: const [SizedBox(width: 56)], // Ortalamak için boşluk
            // Arka Plan Efekti (Blur)
            flexibleSpace: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isScrolled
                    ? BackdropFilter(
                        key: const ValueKey('blurred'),
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('solid'),
                        decoration: BoxDecoration(color: scaffoldBg),
                      ),
              ),
            ),
          ),

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
                    height: 145,
                    child: _buildLiveWidgets(
                      kartRengi,
                      yaziRengi,
                      altYaziRengi,
                    ),
                  ),

                  const SizedBox(height: 0.01), // Ayrım boşluğu
                  // 2. Haber Akışı
                  _buildNewsFeed(
                    kartRengi,
                    yaziRengi,
                    altYaziRengi,
                    golgeRengi,
                  ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: PartnerWidget(cardColor: kartRengi)),
        const SizedBox(width: 15),
        Expanded(
          child: DailyCardsWidget(
            entry: _todayScore,
            isLoading: _isDailyScoreLoading,
            onDailyScoreTap: _openDailyScore,
            onHistoryTap: _openDailyScoreHistory,
            cardColor: kartRengi,
            textColor: yaziRengi,
            mutedColor: altYaziRengi,
          ),
        ),
      ],
    );
  }

  // --- Haber Listesini Oluşturur ---
  Widget _buildNewsFeed(
    Color kartRengi,
    Color yaziRengi,
    Color altYaziRengi,
    Color golgeRengi,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _newsStream,
      builder: (context, snapshot) {
        // Veri yoksa yükleniyor göster
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final visibleDocs = snapshot.data!.docs.where(_isVisibleNews).toList();

        if (visibleDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              "Yayında haber yok.",
              textAlign: TextAlign.center,
              style: GoogleFonts.kadwa(fontSize: 14, color: altYaziRengi),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: visibleDocs.length,
          shrinkWrap: true, // ScrollView içinde olduğu için gerekli
          physics:
              const NeverScrollableScrollPhysics(), // Ana scroll'u kullansın
          itemBuilder: (context, index) {
            final data = visibleDocs[index].data() as Map<String, dynamic>;
            return _buildModernNewsCard(
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
              golgeRengi: golgeRengi,
            );
          },
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
  Widget _buildModernNewsCard({
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
    required Color golgeRengi,
  }) {
    final formattedDate = _formatCreatedAt(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: kartRengi,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: golgeRengi.withValues(alpha: 0.35),
            spreadRadius: 0,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.0),
          onTap: () => _showModernDetailModal(
            title,
            detail,
            summary,
            source,
            sourceUrl,
            kartRengi,
            yaziRengi,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.kadwa(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: yaziRengi,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: GoogleFonts.kadwa(
                    fontSize: 14,
                    color: altYaziRengi,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Detayı oku",
                      style: GoogleFonts.kadwa(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: altYaziRengi,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: altYaziRengi,
                    ),
                  ],
                ),
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
