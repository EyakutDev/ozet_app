import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/screens/daily_score_statistics_screen.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:ozet_app/widgets/app_feedback.dart';

class DailyScoreScreen extends StatefulWidget {
  const DailyScoreScreen({super.key, this.initialEntry});

  final DailyScoreEntry? initialEntry;

  @override
  State<DailyScoreScreen> createState() => _DailyScoreScreenState();
}

class _DailyScoreScreenState extends State<DailyScoreScreen> {
  static const int _defaultScore = 5;

  late final TextEditingController _noteController;
  late final Map<String, int> _scores;

  int _step = 0;
  bool _movingForward = true;

  bool get _isNoteStep => _step == dailyScoreQuestions.length;
  DailyScoreQuestion get _question => dailyScoreQuestions[_step];
  int? get _selectedScore => _isNoteStep ? null : _scores[_question.id];

  double get _average {
    if (_scores.isEmpty) return 0;
    final total = _scores.values.fold<int>(0, (sum, score) => sum + score);
    return total / _scores.length;
  }

  String get _resultLabel => DailyScoreEntry(
    date: DateTime.now(),
    scores: _scores,
    note: '',
  ).summaryLabel;

  @override
  void initState() {
    super.initState();
    _scores = Map<String, int>.from(widget.initialEntry?.scores ?? {});
    _scores.putIfAbsent(dailyScoreQuestions.first.id, () => _defaultScore);
    _noteController = TextEditingController(text: widget.initialEntry?.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectScore(int score) {
    if (_scores[_question.id] == score) return;
    HapticFeedback.selectionClick();
    setState(() => _scores[_question.id] = score);
  }

  void _goNext() {
    if (!_isNoteStep && _selectedScore == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _movingForward = true;
      if (_step < dailyScoreQuestions.length) {
        _step++;
        if (_step < dailyScoreQuestions.length) {
          // Daha once cevaplanmamis her soru gorunur bir orta puanla baslar.
          _scores.putIfAbsent(
            dailyScoreQuestions[_step].id,
            () => _defaultScore,
          );
        }
      }
    });
  }

  void _goBack() {
    if (_step == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _movingForward = false;
      _step--;
    });
  }

  void _save() {
    if (_scores.length != dailyScoreQuestions.length) {
      AppFeedback.show(
        context,
        'Gün kartını oluşturmak için tüm soruları puanlamalısın.',
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context).pop(
      DailyScoreEntry(
        date: DateTime.now(),
        scores: Map<String, int>.unmodifiable(_scores),
        note: _noteController.text.trim(),
      ),
    );
  }

  void _openStatistics() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => DailyScoreStatisticsScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ScorePalette.of(context);
    final content = _isNoteStep
        ? KeyedSubtree(
            key: const ValueKey('note'),
            child: _buildNoteStep(palette),
          )
        : KeyedSubtree(
            key: ValueKey(_question.id),
            child: _buildQuestionStep(palette),
          );

    return Scaffold(
      backgroundColor: palette.scaffold,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            tooltip: 'Geri',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: palette.text,
            style: IconButton.styleFrom(
              backgroundColor: palette.glassStrong,
              side: BorderSide(color: palette.border),
              fixedSize: const Size.square(40),
              shape: const CircleBorder(),
            ),
          ),
        ),
        title: Text(
          'Gününü Değerlendir',
          style: GoogleFonts.inter(
            color: palette.text,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconButton(
                tooltip: 'İstatistikler',
                onPressed: _openStatistics,
                icon: const Icon(Icons.insights_rounded, size: 20),
                color: palette.text,
                style: IconButton.styleFrom(
                  backgroundColor: palette.glassStrong,
                  side: BorderSide(color: palette.border),
                  fixedSize: const Size.square(40),
                  shape: const CircleBorder(),
                  overlayColor: palette.text.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.glass.withValues(alpha: 0.78),
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildProgress(palette),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final begin = Offset(_movingForward ? 0.045 : -0.045, 0);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: begin,
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(_ScorePalette palette) {
    final totalSteps = dailyScoreQuestions.length + 1;
    final stageText = _isNoteStep
        ? 'Son dokunuş'
        : 'Soru ${_step + 1}/${dailyScoreQuestions.length}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(widget.initialEntry?.date ?? DateTime.now()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      key: ValueKey(stageText),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.glassStrong,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        stageText,
                        style: GoogleFonts.inter(
                          color: palette.text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(totalSteps, (index) {
                  final isReached = index <= _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index == totalSteps - 1 ? 0 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isReached ? palette.accent : palette.track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionStep(_ScorePalette palette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight = (constraints.maxHeight - 28)
            .clamp(0.0, double.infinity)
            .toDouble();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            MediaQuery.paddingOf(context).bottom + 18,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GlassSurface(
                      palette: palette,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.controlSurface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Text(
                                  _question.shortTitle,
                                  style: GoogleFonts.inter(
                                    color: palette.text,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                (_step + 1).toString().padLeft(2, '0'),
                                style: GoogleFonts.inter(
                                  color: palette.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _question.title,
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              height: 1.22,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: _ScoreReadout(
                              score: _selectedScore,
                              palette: palette,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            decoration: BoxDecoration(
                              color: palette.controlSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              children: [
                                _DiscreteScoreSlider(
                                  value: _selectedScore,
                                  semanticLabel: _question.shortTitle,
                                  palette: palette,
                                  onChanged: _selectScore,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestionNavigation(palette),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionNavigation(_ScorePalette palette) {
    final canContinue = _selectedScore != null;

    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          if (_step > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: 44,
                child: IconButton(
                  onPressed: _goBack,
                  tooltip: 'Önceki soru',
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                  color: palette.text,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.glassStrong,
                    side: BorderSide(color: palette.border),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 112,
              height: 44,
              child: FilledButton(
                onPressed: canContinue ? _goNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  disabledBackgroundColor: palette.controlSurface,
                  disabledForegroundColor: palette.muted,
                  side: BorderSide(
                    color: canContinue ? palette.accent : palette.border,
                  ),
                  overlayColor: palette.onAccent.withValues(alpha: 0.10),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'İleri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteStep(_ScorePalette palette) {
    final scoreText = _average.toStringAsFixed(1).replaceAll('.', ',');

    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight = (constraints.maxHeight - 28)
            .clamp(0.0, double.infinity)
            .toDouble();

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.paddingOf(context).bottom + 18,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GlassSurface(
                      palette: palette,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Son dokunuş',
                            style: GoogleFonts.inter(
                              color: palette.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Bugünün sonucu',
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: palette.controlSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: palette.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.shadow,
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      scoreText,
                                      style: GoogleFonts.inter(
                                        color: palette.accent,
                                        fontSize: 29,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '/10',
                                      style: GoogleFonts.inter(
                                        color: palette.muted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _resultLabel,
                                      style: GoogleFonts.inter(
                                        color: palette.text,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDate(
                                        widget.initialEntry?.date ??
                                            DateTime.now(),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: palette.muted,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        height: 1.35,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Divider(color: palette.border, height: 1),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Bugünden kalan not',
                                  style: GoogleFonts.inter(
                                    color: palette.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.controlSurface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Text(
                                  'İsteğe bağlı',
                                  style: GoogleFonts.inter(
                                    color: palette.muted,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            maxLength: 200,
                            maxLines: 5,
                            minLines: 4,
                            textInputAction: TextInputAction.newline,
                            cursorColor: palette.accent,
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Bugünden sende kalmasını istediğin şeyi yaz.',
                              hintStyle: GoogleFonts.inter(
                                color: palette.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                letterSpacing: 0,
                              ),
                              counterStyle: GoogleFonts.inter(
                                color: palette.muted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                              filled: true,
                              fillColor: palette.controlSurface,
                              contentPadding: const EdgeInsets.all(15),
                              enabledBorder: _fieldBorder(palette.border),
                              focusedBorder: _fieldBorder(
                                palette.accent,
                                width: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNoteNavigation(palette),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteNavigation(_ScorePalette palette) {
    final buttonText = widget.initialEntry == null
        ? 'Gün kartını oluştur'
        : 'Gün kartını güncelle';

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 44,
            child: IconButton(
              onPressed: _goBack,
              tooltip: 'Önceki soru',
              icon: const Icon(Icons.arrow_back_rounded, size: 19),
              color: palette.text,
              style: IconButton.styleFrom(
                backgroundColor: palette.glassStrong,
                side: BorderSide(color: palette.border),
                shape: const CircleBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  side: BorderSide(color: palette.accent),
                  overlayColor: palette.onAccent.withValues(alpha: 0.10),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        buttonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.check_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.palette,
    required this.child,
    required this.padding,
  });

  static const _radius = 24.0;

  final _ScorePalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.glass,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: palette.border),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _ScoreReadout extends StatelessWidget {
  const _ScoreReadout({required this.score, required this.palette});

  final int? score;
  final _ScorePalette palette;

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final ringProgress = hasScore ? score! / 10 : 0.0;
    final description = hasScore ? _scoreDescription(score!) : 'Bir puan seç';

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: palette.glassStrong,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: hasScore ? 20 : 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(end: ringProgress),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        color: palette.accent,
                        backgroundColor: palette.track,
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: 0.95, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Column(
                    key: ValueKey(score),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score?.toString() ?? '–',
                        style: GoogleFonts.inter(
                          color: hasScore ? palette.accent : palette.muted,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 0.95,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/10',
                        style: GoogleFonts.inter(
                          color: palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: Container(
            key: ValueKey(description),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.glassStrong,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              description,
              style: GoogleFonts.inter(
                color: hasScore ? palette.text : palette.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscreteScoreSlider extends StatelessWidget {
  const _DiscreteScoreSlider({
    required this.value,
    required this.semanticLabel,
    required this.palette,
    required this.onChanged,
  });

  final int? value;
  final String semanticLabel;
  final _ScorePalette palette;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel puanı',
      value: value == null ? 'Seçilmedi' : '$value / 10',
      increasedValue: value == null || value == 10
          ? null
          : (value! + 1).toString(),
      decreasedValue: value == null || value == 1
          ? null
          : (value! - 1).toString(),
      onIncrease: value == null
          ? () => onChanged(1)
          : value! < 10
          ? () => onChanged(value! + 1)
          : null,
      onDecrease: value != null && value! > 1
          ? () => onChanged(value! - 1)
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const thumbSize = 32.0;
          final trackWidth = (constraints.maxWidth - thumbSize)
              .clamp(1.0, double.infinity)
              .toDouble();
          final progress = value == null ? 0.0 : (value! - 1) / 9;

          void updateScore(double dx) {
            final normalized = ((dx - thumbSize / 2) / trackWidth).clamp(
              0.0,
              1.0,
            );
            onChanged((normalized * 9).round() + 1);
          }

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => updateScore(details.localPosition.dx),
              onHorizontalDragStart: (details) =>
                  updateScore(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  updateScore(details.localPosition.dx),
              child: SizedBox(
                height: 62,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: thumbSize / 2,
                      right: thumbSize / 2,
                      top: 19,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (value != null)
                      Positioned(
                        left: thumbSize / 2,
                        top: 19,
                        width: trackWidth * progress,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    Positioned(
                      left: thumbSize / 2 - 2,
                      right: thumbSize / 2 - 2,
                      top: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(10, (index) {
                          final isReached = value != null && index < value!;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: isReached
                                  ? palette.onAccent.withValues(alpha: 0.52)
                                  : palette.muted.withValues(alpha: 0.36),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 4),
                          );
                        }),
                      ),
                    ),
                    if (value != null)
                      Positioned(
                        key: const ValueKey('daily-score-thumb'),
                        left: trackWidth * progress,
                        top: 6,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.onAccent.withValues(alpha: 0.26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '$value',
                            style: GoogleFonts.inter(
                              color: palette.onAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    for (final scaleValue in const [1, 5, 10])
                      Positioned(
                        key: ValueKey('daily-score-scale-$scaleValue'),
                        left: trackWidth * ((scaleValue - 1) / 9),
                        top: 48,
                        width: thumbSize,
                        child: ExcludeSemantics(
                          child: Text(
                            '$scaleValue',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: palette.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScorePalette {
  const _ScorePalette({
    required this.scaffold,
    required this.text,
    required this.muted,
    required this.glass,
    required this.glassStrong,
    required this.controlSurface,
    required this.border,
    required this.track,
    required this.accent,
    required this.onAccent,
    required this.shadow,
  });

  final Color scaffold;
  final Color text;
  final Color muted;
  final Color glass;
  final Color glassStrong;
  final Color controlSurface;
  final Color border;
  final Color track;
  final Color accent;
  final Color onAccent;
  final Color shadow;

  factory _ScorePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _ScorePalette(
      scaffold: isDark ? AppThemePalette.darkScaffold : const Color(0xFFF2F2F4),
      text: isDark ? AppThemePalette.darkText : const Color(0xFF111114),
      muted: isDark ? AppThemePalette.darkMuted : const Color(0xFF6E6E73),
      glass: isDark
          ? AppThemePalette.darkSurface.withValues(alpha: 0.80)
          : Colors.white.withValues(alpha: 0.74),
      glassStrong: isDark
          ? AppThemePalette.darkSurfaceStrong.withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.86),
      controlSurface: isDark
          ? Colors.white.withValues(alpha: 0.065)
          : Colors.white.withValues(alpha: 0.62),
      border: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      track: isDark
          ? Colors.white.withValues(alpha: 0.13)
          : Colors.black.withValues(alpha: 0.09),
      accent: isDark ? AppThemePalette.darkText : const Color(0xFF111114),
      onAccent: isDark ? AppThemePalette.darkOnAccent : Colors.white,
      shadow: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
    );
  }
}

String _scoreDescription(int score) {
  if (score <= 2) return 'Oldukça düşük';
  if (score <= 4) return 'Düşük';
  if (score <= 6) return 'Orta';
  if (score <= 8) return 'İyi';
  return 'Çok iyi';
}

String _formatDate(DateTime date) {
  const weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
