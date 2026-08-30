import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidGlassSliverAppBar extends StatelessWidget {
  const LiquidGlassSliverAppBar({
    super.key,
    required this.isDark,
    required this.isScrolled,
    required this.leading,
    required this.title,
    required this.systemOverlayStyle,
    this.toolbarHeight = 58,
  });

  final bool isDark;
  final bool isScrolled;
  final Widget leading;
  final Widget title;
  final SystemUiOverlayStyle systemOverlayStyle;
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    final glassTint = isDark
        ? Colors.black.withValues(alpha: isScrolled ? 0.17 : 0.10)
        : Colors.white.withValues(alpha: isScrolled ? 0.14 : 0.07);
    final edgeHighlight = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.72);

    return SliverAppBar(
      pinned: true,
      floating: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: 70,
      titleSpacing: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Center(child: leading),
      ),
      title: title,
      centerTitle: true,
      actions: const [SizedBox(width: 70)],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: glassTint,
              boxShadow: isScrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.065,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : const [],
            ),
            // Yansima ve ust kenar isigi, ayirici cizgi kullanmadan cami tanimlar.
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                                Colors.white.withValues(alpha: 0.24),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.07),
                              ],
                        stops: const [0, 0.28, 0.72, 1],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: double.infinity,
                    height: 0.8,
                    color: edgeHighlight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassIconButton extends StatelessWidget {
  const LiquidGlassIconButton({
    super.key,
    required this.isDark,
    required this.foregroundColor,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 19,
  });

  final bool isDark;
  final Color foregroundColor;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ring = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: isDark ? 0.88 : 1),
        Colors.white.withValues(alpha: isDark ? 0.28 : 0.48),
        Colors.white.withValues(alpha: isDark ? 0.66 : 0.84),
        Colors.white.withValues(alpha: isDark ? 0.18 : 0.34),
        Colors.white.withValues(alpha: isDark ? 0.88 : 1),
      ],
      stops: const [0, 0.22, 0.5, 0.78, 1],
    );
    final lens = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 1.05,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.26),
              Colors.white.withValues(alpha: 0.09),
              Colors.white.withValues(alpha: 0.035),
            ]
          : [
              Colors.white.withValues(alpha: 0.62),
              Colors.white.withValues(alpha: 0.24),
              Colors.white.withValues(alpha: 0.10),
            ],
      stops: const [0, 0.58, 1],
    );

    return SizedBox.square(
      dimension: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ring,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: lens),
                child: IconButton(
                  tooltip: tooltip,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onPressed();
                  },
                  alignment: Alignment.center,
                  icon: Icon(icon, size: iconSize),
                  color: foregroundColor,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(40),
                    minimumSize: const Size.square(40),
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    overlayColor: foregroundColor.withValues(alpha: 0.08),
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
