import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFeedbackType { info, success, error }

class AppFeedback {
  static const Color _accentBlue = Color(0xFF9EC8ED);
  static const Color _primaryNavy = Color(0xFF0A2342);

  // Uygulamadaki kisa hata/basari mesajlarini tek bir tema dilinde gosterir.
  static void show(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    final icon = switch (type) {
      AppFeedbackType.success => Icons.check_circle_outline,
      AppFeedbackType.error => Icons.error_outline,
      AppFeedbackType.info => Icons.info_outline,
    };
    final accent = switch (type) {
      AppFeedbackType.success => _accentBlue,
      AppFeedbackType.error => const Color(0xFFE57373),
      AppFeedbackType.info => isDark ? _accentBlue : _primaryNavy,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.kadwa(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
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
