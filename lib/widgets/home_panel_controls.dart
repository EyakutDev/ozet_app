import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ana sayfa panelinde kullanılan sade, düşük kontrastlı ikon kontrolü.
class HomePanelIcon extends StatelessWidget {
  const HomePanelIcon({
    super.key,
    required this.icon,
    required this.foregroundColor,
    this.onTap,
    this.tooltip,
    this.size = 27,
    this.iconSize = 14.5,
  });

  final IconData icon;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final control = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.34),
        shape: BoxShape.circle,
        border: Border.all(
          color: foregroundColor.withValues(alpha: isDark ? 0.12 : 0.07),
        ),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: foregroundColor.withValues(alpha: 0.78),
      ),
    );

    if (onTap == null) return control;

    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: control,
        ),
      ),
    );
  }
}

class HomePanelPageIndicator extends StatelessWidget {
  const HomePanelPageIndicator({
    super.key,
    required this.activeIndex,
    required this.activeColor,
    required this.mutedColor,
  });

  final int activeIndex;
  final Color activeColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
          width: isActive ? 11 : 4,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.78)
                : mutedColor.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class HomePanelFooter extends StatelessWidget {
  const HomePanelFooter({
    super.key,
    required this.activeIndex,
    required this.foregroundColor,
    required this.mutedColor,
    this.actionLabel,
    this.leading,
    this.showChevron = true,
  });

  final int? activeIndex;
  final Color foregroundColor;
  final Color mutedColor;
  final String? actionLabel;
  final Widget? leading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final indicator = activeIndex == null
        ? const SizedBox.shrink()
        : HomePanelPageIndicator(
            activeIndex: activeIndex!,
            activeColor: foregroundColor,
            mutedColor: mutedColor,
          );

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          if (leading != null) ...[
            Expanded(child: leading!),
            const SizedBox(width: 6),
          ] else ...[
            indicator,
            const Spacer(),
          ],
          if (leading != null) indicator,
          if (actionLabel != null) ...[
            if (leading != null || activeIndex != null)
              const SizedBox(width: 7),
            Flexible(
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: foregroundColor.withValues(alpha: 0.76),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: foregroundColor.withValues(alpha: 0.62),
            ),
          ],
        ],
      ),
    );
  }
}
