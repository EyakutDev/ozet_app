import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/screens/auth_screen.dart';
import 'package:ozet_app/services/onboarding_service.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:ozet_app/widgets/app_feedback.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.service, this.previewMode = false});

  final OnboardingService? service;
  final bool previewMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late final OnboardingService _service;
  int _currentPage = 0;
  bool _isCompleting = false;

  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _service = widget.service ?? OnboardingService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isCompleting) return;
    if (_currentPage == _pageCount - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_currentPage == 0 || _isCompleting) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_isCompleting) return;
    if (widget.previewMode) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isCompleting = true);
    try {
      await _service.complete();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    } catch (error, stackTrace) {
      final failure = await AppErrorHandler.capture(
        error,
        stackTrace,
        operation: 'onboarding.complete',
        fallbackMessage: 'Başlangıç adımı tamamlanamadı.',
      );
      if (!mounted) return;
      setState(() => _isCompleting = false);
      AppFeedback.showFailure(context, failure, onRetry: _finish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _OnboardingPalette.of(context);
    final media = MediaQuery.of(context);
    final overlay = palette.isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: palette.scaffold,
        body: Stack(
          children: [
            Positioned.fill(
              child: _FullScreenBackdrop(page: _currentPage, palette: palette),
            ),
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                physics: _isCompleting
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = page);
                },
                children: [
                  _FullScreenPage(
                    key: const ValueKey('onboarding-page-0'),
                    pageIndex: 0,
                    pageController: _pageController,
                    eyebrow: 'GÜNDEM',
                    title: 'Gündem, uzatmadan.',
                    description:
                        'Kaydırdıkça yeni haberleri gör, başlığı kısa özetiyle değerlendir ve devamını uygulama içindeki kaynak görünümünde oku.',
                    visual: _NewsScene(palette: palette),
                    palette: palette,
                    topInset: media.padding.top + 72,
                    bottomInset: media.padding.bottom + 98,
                  ),
                  _FullScreenPage(
                    key: const ValueKey('onboarding-page-1'),
                    pageIndex: 1,
                    pageController: _pageController,
                    eyebrow: 'PARTNER',
                    title: 'Birlikte, ama sakin.',
                    description:
                        'Partnerinle eşleş; hızlı durumunu, mini notunu veya kendi çizimini yalnızca ona gönder.',
                    visual: _PartnerScene(palette: palette),
                    palette: palette,
                    topInset: media.padding.top + 72,
                    bottomInset: media.padding.bottom + 98,
                  ),
                  _FullScreenPage(
                    key: const ValueKey('onboarding-page-2'),
                    pageIndex: 2,
                    pageController: _pageController,
                    eyebrow: 'GÜNÜN PUANI',
                    title: 'Günün sende kalsın.',
                    description:
                        'Beş başlıktaki puanlarından günlük skorunu çıkar, gün kartını oluştur; takvimden geçmişini ve haftalık analizini gör.',
                    visual: _DailyScoreScene(palette: palette),
                    palette: palette,
                    topInset: media.padding.top + 72,
                    bottomInset: media.padding.bottom + 98,
                  ),
                ],
              ),
            ),
            Positioned(
              top: media.padding.top + 8,
              left: 18,
              right: 14,
              child: _TopBar(
                palette: palette,
                busy: _isCompleting,
                label: widget.previewMode ? 'Kapat' : 'Atla',
                onSkip: _finish,
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: media.padding.bottom + 10,
              child: _BottomDock(
                page: _currentPage,
                pageCount: _pageCount,
                busy: _isCompleting,
                palette: palette,
                finalLabel: widget.previewMode ? 'Bitir' : 'Başla',
                onBack: _back,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenPage extends StatelessWidget {
  const _FullScreenPage({
    super.key,
    required this.pageIndex,
    required this.pageController,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.visual,
    required this.palette,
    required this.topInset,
    required this.bottomInset,
  });

  final int pageIndex;
  final PageController pageController;
  final String eyebrow;
  final String title;
  final String description;
  final Widget visual;
  final _OnboardingPalette palette;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visualHeight = (constraints.maxHeight * 0.55)
            .clamp(300.0, 430.0)
            .toDouble();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topInset, 20, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - topInset - bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: visualHeight,
                  width: double.infinity,
                  child: _PageVisualMotion(
                    pageIndex: pageIndex,
                    controller: pageController,
                    child: visual,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  eyebrow,
                  style: GoogleFonts.inter(
                    color: palette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      color: palette.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.42,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageVisualMotion extends StatelessWidget {
  const _PageVisualMotion({
    required this.pageIndex,
    required this.controller,
    required this.child,
  });

  final int pageIndex;
  final PageController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final currentPage = controller.hasClients
            ? controller.page ?? controller.initialPage.toDouble()
            : pageIndex.toDouble();
        final distance = (currentPage - pageIndex).clamp(-1.0, 1.0);
        final depth = distance.abs();

        return Transform.translate(
          offset: Offset(distance * -18, depth * 4),
          child: Transform.scale(scale: 1 - (depth * 0.025), child: child),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.busy,
    required this.label,
    required this.onSkip,
  });

  final _OnboardingPalette palette;
  final bool busy;
  final String label;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo_ozet.png',
      width: 82,
      height: 42,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Özet',
    );

    return Row(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(palette.text, BlendMode.srcIn),
          child: logo,
        ),
        const Spacer(),
        TextButton(
          key: const ValueKey('onboarding-skip'),
          onPressed: busy ? null : onSkip,
          style: TextButton.styleFrom(
            foregroundColor: palette.muted,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.page,
    required this.pageCount,
    required this.busy,
    required this.palette,
    required this.finalLabel,
    required this.onBack,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final bool busy;
  final _OnboardingPalette palette;
  final String finalLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = page == pageCount - 1;
    return Row(
      children: [
        IgnorePointer(
          ignoring: page == 0,
          child: AnimatedOpacity(
            opacity: page == 0 ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            child: _GlassSurface(
              palette: palette,
              radius: 99,
              child: SizedBox.square(
                dimension: 48,
                child: IconButton(
                  tooltip: 'Geri',
                  onPressed: busy ? null : onBack,
                  color: palette.text,
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: '${page + 1} / $pageCount',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                final selected = index == page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 25 : 6,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected ? palette.text : palette.borderStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isLast ? 108 : 52,
          height: 52,
          child: FilledButton(
            key: const ValueKey('onboarding-next'),
            onPressed: busy ? null : onNext,
            style: FilledButton.styleFrom(
              backgroundColor: palette.text,
              foregroundColor: palette.onAccent,
              disabledBackgroundColor: palette.text.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isLast ? 18 : 99),
              ),
            ),
            child: busy
                ? SizedBox.square(
                    key: const ValueKey('onboarding-loading'),
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onAccent,
                    ),
                  )
                : isLast
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          finalLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(Icons.arrow_forward_rounded, size: 17),
                      ],
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _NewsScene extends StatefulWidget {
  const _NewsScene({required this.palette});

  final _OnboardingPalette palette;

  @override
  State<_NewsScene> createState() => _NewsSceneState();
}

class _NewsSceneState extends State<_NewsScene> {
  static const _items = [
    _OnboardingNewsData(
      title:
          'Şanghay İşbirliği Örgütü’nün 25. yılı: Türkiye’nin ilişkisi nasıl şekillendi?',
      summary:
          'Zirvenin öne çıkan başlıkları ve Türkiye açısından taşıdığı anlam kısa bir özette.',
      date: '1 Eyl',
    ),
    _OnboardingNewsData(
      title:
          'Modi’nin Ukrayna Savaşı’nı Bitirme Çağrısına Putin’den Belirsiz Yanıt',
      summary:
          'Liderlerin açıklamalarındaki kritik noktalar ve görüşmenin sonucu birkaç cümlede.',
      date: '1 Eyl',
    ),
    _OnboardingNewsData(
      title: 'Almanya Leipzig’deki drone saldırısından Rusya’yı sorumlu tuttu',
      summary:
          'Olayın ardından yapılan açıklamalar ve bölgede alınan yeni kararlar özetlendi.',
      date: '1 Eyl',
    ),
  ];

  int _selectedIndex = 0;

  void _select(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Row(
            children: [
              Text(
                'Bugünün akışı',
                style: GoogleFonts.inter(
                  color: palette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '3 kısa haber',
                style: GoogleFonts.inter(
                  color: palette.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              return Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 360 + (index * 90)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * (14 + index * 4)),
                            child: child,
                          ),
                        ),
                        child: _OnboardingNewsItem(
                          item: item,
                          selected: _selectedIndex == index,
                          palette: palette,
                          onTap: () => _select(index),
                        ),
                      ),
                    ),
                    if (index != _items.length - 1)
                      Divider(color: palette.borderStrong, height: 1),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _OnboardingNewsData {
  const _OnboardingNewsData({
    required this.title,
    required this.summary,
    required this.date,
  });

  final String title;
  final String summary;
  final String date;
}

class _OnboardingNewsItem extends StatelessWidget {
  const _OnboardingNewsItem({
    required this.item,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final _OnboardingNewsData item;
  final bool selected;
  final _OnboardingPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(4, selected ? 5 : 7, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NewsMetaChip(label: 'Haber', palette: palette),
                  const SizedBox(width: 6),
                  _NewsMetaChip(label: 'bbc rss', palette: palette),
                  const SizedBox(width: 7),
                  Text(
                    item.date,
                    style: GoogleFonts.inter(
                      color: palette.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.text,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kadwa(
                  color: palette.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Align(
                    key: ValueKey(selected),
                    alignment: Alignment.topLeft,
                    child: Text(
                      item.summary,
                      maxLines: selected ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                        height: 1.28,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsMetaChip extends StatelessWidget {
  const _NewsMetaChip({required this.label, required this.palette});

  final String label;
  final _OnboardingPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? 0.78 : 0.90),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: palette.text,
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PartnerScene extends StatefulWidget {
  const _PartnerScene({required this.palette});

  final _OnboardingPalette palette;

  @override
  State<_PartnerScene> createState() => _PartnerSceneState();
}

class _PartnerSceneState extends State<_PartnerScene> {
  bool _shared = false;

  void _toggleShare() {
    HapticFeedback.lightImpact();
    setState(() => _shared = !_shared);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.26 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 66,
                height: 42,
                child: Stack(
                  children: [
                    _PartnerAvatar(label: 'S', palette: palette),
                    Positioned(
                      left: 26,
                      child: _PartnerAvatar(
                        label: 'E',
                        palette: palette,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner kartın',
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Eşleşme aktif',
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock_outline_rounded, size: 17, color: palette.muted),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hızlı durum',
              style: GoogleFonts.inter(
                color: palette.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _PartnerStatusChip(
                label: 'Sakinim',
                icon: Icons.self_improvement_rounded,
                selected: true,
                palette: palette,
              ),
              const SizedBox(width: 6),
              _PartnerStatusChip(
                label: 'Konuşalım',
                icon: Icons.chat_bubble_outline_rounded,
                palette: palette,
              ),
              const SizedBox(width: 6),
              _PartnerStatusChip(
                label: 'Birazdan',
                icon: Icons.schedule_rounded,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
                    decoration: BoxDecoration(
                      color: palette.scaffold.withValues(
                        alpha: palette.isDark ? 0.72 : 0.76,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 14,
                              color: palette.text,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Mini not',
                              style: GoogleFonts.inter(
                                color: palette.text,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                            const Spacer(),
                            SizedBox.square(
                              dimension: 30,
                              child: IconButton(
                                key: const ValueKey(
                                  'onboarding-partner-action',
                                ),
                                tooltip: 'Notu paylaş',
                                padding: EdgeInsets.zero,
                                onPressed: _toggleShare,
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  child: Icon(
                                    _shared
                                        ? Icons.done_rounded
                                        : Icons.arrow_upward_rounded,
                                    key: ValueKey(_shared),
                                    size: 15,
                                  ),
                                ),
                                color: _shared
                                    ? palette.onAccent
                                    : palette.text,
                                style: IconButton.styleFrom(
                                  backgroundColor: _shared
                                      ? palette.text
                                      : palette.surface,
                                  side: BorderSide(color: palette.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Bugün seni düşündüm.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            _shared ? 'Paylaşıldı' : 'Partnerine gönder',
                            key: ValueKey(_shared),
                            style: GoogleFonts.inter(
                              color: palette.muted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 98,
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 6),
                  decoration: BoxDecoration(
                    color: palette.scaffold.withValues(
                      alpha: palette.isDark ? 0.72 : 0.76,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            size: 14,
                            color: palette.text,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Çizim',
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: CustomPaint(
                          painter: _MiniDrawingPainter(color: palette.text),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 12,
                color: palette.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Durumun, notun ve çizimin yalnızca partnerinde görünür.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({
    required this.label,
    required this.palette,
    this.filled = false,
  });

  final String label;
  final _OnboardingPalette palette;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? palette.text : palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: palette.borderStrong),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: filled ? palette.onAccent : palette.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PartnerStatusChip extends StatelessWidget {
  const _PartnerStatusChip({
    required this.label,
    required this.icon,
    required this.palette,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final _OnboardingPalette palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.text : palette.scaffold,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? palette.text : palette.border),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected ? palette.onAccent : palette.text,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? palette.onAccent : palette.text,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyScoreScene extends StatefulWidget {
  const _DailyScoreScene({required this.palette});

  final _OnboardingPalette palette;

  @override
  State<_DailyScoreScene> createState() => _DailyScoreSceneState();
}

class _DailyScoreSceneState extends State<_DailyScoreScene> {
  int _score = 7;

  void _updateScore(int value) {
    if (value == _score) return;
    HapticFeedback.selectionClick();
    setState(() => _score = value);
  }

  double get _average => (_score + 29) / 5;

  String get _label {
    if (_average >= 8.5) return 'Çok iyi geçti';
    if (_average >= 7) return 'İyi geçti';
    if (_average >= 5) return 'Dengeliydi';
    if (_average >= 3) return 'Zorlayıcıydı';
    return 'Zor geçti';
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final averageText = _average.toStringAsFixed(1).replaceAll('.', ',');

    return Column(
      children: [
        Row(
          children: [
            _ScoreMetaPill(label: '1 / 5', palette: palette),
            const SizedBox(width: 7),
            Text(
              'Ruh hali',
              style: GoogleFonts.inter(
                color: palette.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            Text(
              'Gününü değerlendir',
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün ruh halin nasıldı?',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: Text(
                              '$_score',
                              key: ValueKey(_score),
                              style: GoogleFonts.inter(
                                color: palette.text,
                                fontSize: 31,
                                fontWeight: FontWeight.w700,
                                height: 0.92,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3, bottom: 2),
                            child: Text(
                              '/10',
                              style: GoogleFonts.inter(
                                color: palette.muted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 116,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.borderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: palette.isDark ? 0.24 : 0.07,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: palette.text,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Gün kartın',
                          style: GoogleFonts.inter(
                            color: palette.muted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      averageText,
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        _OnboardingScoreSlider(
          value: _score,
          palette: palette,
          onChanged: _updateScore,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(
                      alpha: palette.isDark ? 0.84 : 0.94,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 13,
                            color: palette.text,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Takvim',
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final selected = index == 4;
                          return Container(
                            width: 15,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? palette.text : palette.scaffold,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selected ? palette.text : palette.border,
                              ),
                            ),
                            child: Text(
                              (18 + index).toString(),
                              style: GoogleFonts.inter(
                                color: selected
                                    ? palette.onAccent
                                    : palette.muted,
                                fontSize: 6.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(
                      alpha: palette.isDark ? 0.84 : 0.94,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            size: 13,
                            color: palette.text,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Haftalık analiz',
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: CustomPaint(
                          painter: _MiniAnalysisPainter(
                            color: palette.text,
                            guide: palette.border,
                            score: _score,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreMetaPill extends StatelessWidget {
  const _ScoreMetaPill({required this.label, required this.palette});

  final String label;
  final _OnboardingPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? 0.82 : 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: palette.text,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _OnboardingScoreSlider extends StatelessWidget {
  const _OnboardingScoreSlider({
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  final int value;
  final _OnboardingPalette palette;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('onboarding-score-slider'),
      label: 'Günün puanı',
      value: '$value / 10',
      increasedValue: value < 10 ? (value + 1).toString() : null,
      decreasedValue: value > 1 ? (value - 1).toString() : null,
      onIncrease: value < 10 ? () => onChanged(value + 1) : null,
      onDecrease: value > 1 ? () => onChanged(value - 1) : null,
      child: Container(
        height: 61,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.surface.withValues(
            alpha: palette.isDark ? 0.82 : 0.94,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const thumbSize = 28.0;
            final trackWidth = constraints.maxWidth - thumbSize;
            final progress = (value - 1) / 9;

            void update(double dx) {
              final normalized = ((dx - thumbSize / 2) / trackWidth).clamp(
                0.0,
                1.0,
              );
              onChanged((normalized * 9).round() + 1);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => update(details.localPosition.dx),
              onHorizontalDragStart: (details) =>
                  update(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  update(details.localPosition.dx),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: thumbSize / 2,
                    right: thumbSize / 2,
                    top: 16,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.borderStrong,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbSize / 2,
                    top: 16,
                    width: trackWidth * progress,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.text,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbSize / 2 - 1,
                    right: thumbSize / 2 - 1,
                    top: 17,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        10,
                        (index) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: index < value
                                ? palette.onAccent.withValues(alpha: 0.60)
                                : palette.muted.withValues(alpha: 0.32),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 3),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    left: trackWidth * progress,
                    top: 4,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.text,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.onAccent.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: palette.isDark ? 0.30 : 0.12,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$value',
                        style: GoogleFonts.inter(
                          color: palette.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  for (final scaleValue in const [1, 5, 10])
                    Positioned(
                      left: trackWidth * ((scaleValue - 1) / 9),
                      top: 41,
                      width: thumbSize,
                      child: Text(
                        '$scaleValue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniAnalysisPainter extends CustomPainter {
  const _MiniAnalysisPainter({
    required this.color,
    required this.guide,
    required this.score,
  });

  final Color color;
  final Color guide;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.78),
      guidePaint,
    );

    final values = <double>[5.8, 6.4, 5.9, 7.1, score.toDouble()];
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height * (1 - values[index] / 10);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.2, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniAnalysisPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.guide != guide ||
        oldDelegate.score != score;
  }
}

class _MiniDrawingPainter extends CustomPainter {
  const _MiniDrawingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.60)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.18,
        size.width * 0.48,
        size.height * 0.88,
        size.width * 0.62,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.14,
        size.width * 0.82,
        size.height * 0.68,
        size.width * 0.88,
        size.height * 0.34,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniDrawingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _FullScreenBackdrop extends StatelessWidget {
  const _FullScreenBackdrop({required this.page, required this.palette});

  final int page;
  final _OnboardingPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.scaffold,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackdropLinePainter(color: palette.border),
            ),
          ),
          Positioned(
            right: -12,
            top: MediaQuery.paddingOf(context).top + 64,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '0${page + 1}',
                key: ValueKey(page),
                style: GoogleFonts.inter(
                  color: palette.text.withValues(alpha: 0.035),
                  fontSize: 128,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.palette,
    required this.child,
    required this.radius,
  });

  final _OnboardingPalette palette;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.glass,
            borderRadius: borderRadius,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.22 : 0.07,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BackdropLinePainter extends CustomPainter {
  const _BackdropLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.12, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, 0),
      Offset(size.width * 0.88, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _OnboardingPalette {
  const _OnboardingPalette({
    required this.isDark,
    required this.scaffold,
    required this.surface,
    required this.glass,
    required this.text,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.onAccent,
  });

  factory _OnboardingPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _OnboardingPalette(
      isDark: isDark,
      scaffold: isDark ? AppThemePalette.darkScaffold : const Color(0xFFF4F4F5),
      surface: isDark ? AppThemePalette.darkSurface : Colors.white,
      glass: isDark
          ? AppThemePalette.darkSurface.withValues(alpha: 0.74)
          : Colors.white.withValues(alpha: 0.70),
      text: isDark ? AppThemePalette.darkText : const Color(0xFF111114),
      muted: isDark ? AppThemePalette.darkMuted : const Color(0xFF6E6E73),
      border: isDark
          ? Colors.white.withValues(alpha: 0.11)
          : Colors.black.withValues(alpha: 0.08),
      borderStrong: isDark
          ? Colors.white.withValues(alpha: 0.22)
          : Colors.black.withValues(alpha: 0.16),
      onAccent: isDark ? AppThemePalette.darkOnAccent : Colors.white,
    );
  }

  final bool isDark;
  final Color scaffold;
  final Color surface;
  final Color glass;
  final Color text;
  final Color muted;
  final Color border;
  final Color borderStrong;
  final Color onAccent;
}
