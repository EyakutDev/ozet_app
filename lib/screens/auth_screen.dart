import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ozet_app/core/diagnostics/app_logger.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/screens/home_screen.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:ozet_app/widgets/app_feedback.dart';
import 'package:ozet_app/widgets/liquid_glass_app_bar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      try {
        await _googleSignIn.signInSilently();
      } catch (error) {
        AppLogger.event(
          'google_silent_sign_in_failed',
          level: AppLogLevel.warning,
          context: {'errorType': error.runtimeType.toString()},
        );
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-tokens',
          message: 'Google kimlik bilgileri alınamadı. Tekrar deneyin.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      if (!mounted) return;
      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (error, stackTrace) {
      await _showOperationFailure(
        error,
        stackTrace,
        operation: 'auth.google_sign_in',
        fallbackMessage: 'Google ile giriş tamamlanamadı.',
        onRetry: _signInWithGoogle,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAuthForm() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLoginMode && name.isEmpty)) {
      _showSnackBar(
        'Lütfen tüm alanları doldurun.',
        type: AppFeedbackType.error,
      );
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar(
        'Geçerli bir e-posta adresi girin.',
        type: AppFeedbackType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      late UserCredential userCredential;
      if (isLoginMode) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user?.updateDisplayName(name);
      }

      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (error, stackTrace) {
      await _showOperationFailure(
        error,
        stackTrace,
        operation: isLoginMode ? 'auth.email_sign_in' : 'auth.register',
        fallbackMessage: isLoginMode
            ? 'Giriş işlemi tamamlanamadı.'
            : 'Hesap oluşturulamadı.',
        onRetry: _submitAuthForm,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar(
        'Şifre sıfırlama için e-posta adresinizi girin.',
        type: AppFeedbackType.error,
      );
      _emailFocus.requestFocus();
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar(
        'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
        type: AppFeedbackType.success,
      );
    } catch (error, stackTrace) {
      await _showOperationFailure(
        error,
        stackTrace,
        operation: 'auth.password_reset',
        fallbackMessage: 'Şifre sıfırlama bağlantısı gönderilemedi.',
        onRetry: _resetPassword,
      );
    }
  }

  Future<void> _showOperationFailure(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    required String fallbackMessage,
    VoidCallback? onRetry,
  }) async {
    final failure = await AppErrorHandler.capture(
      error,
      stackTrace,
      operation: operation,
      fallbackMessage: fallbackMessage,
    );
    if (!mounted) return;
    AppFeedback.showFailure(context, failure, onRetry: onRetry);
  }

  void _showSnackBar(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    if (!mounted) return;
    AppFeedback.show(context, message, type: type);
  }

  void _setMode(bool loginMode) {
    if (isLoginMode == loginMode || _isLoading) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      isLoginMode = loginMode;
      _isPasswordVisible = false;
    });
  }

  void _continueWithoutAccount() {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final palette = _AuthPalette.of(context);
    final overlayStyle = palette.isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: palette.scaffold,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minContentHeight = constraints.maxHeight > 32
                    ? constraints.maxHeight - 32
                    : 0.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandHeader(palette),
                            const SizedBox(height: 26),
                            _buildModeSwitch(palette),
                            const SizedBox(height: 22),
                            AutofillGroup(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  reverseDuration: const Duration(
                                    milliseconds: 190,
                                  ),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                        return Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        );
                                      },
                                  transitionBuilder: (child, animation) {
                                    final scale = Tween<double>(
                                      begin: 0.985,
                                      end: 1,
                                    ).animate(animation);
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: scale,
                                        alignment: Alignment.topCenter,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildForm(palette),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildPrimaryButton(palette),
                            const SizedBox(height: 18),
                            _buildDivider(palette),
                            const SizedBox(height: 18),
                            _buildGoogleButton(palette),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(_AuthPalette palette) {
    final logo = Image.asset(
      'assets/logo_ozet.png',
      height: 124,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Özet',
    );
    final themedLogo = palette.isDark
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: logo,
          )
        : logo;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              themedLogo,
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  isLoginMode ? 'Hoş geldin' : 'Hesabını oluştur',
                  key: ValueKey(isLoginMode),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gündemi kısa, sakin ve net takip et.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: palette.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: LiquidGlassIconButton(
            isDark: palette.isDark,
            foregroundColor: palette.text,
            icon: Icons.close_rounded,
            iconSize: 20,
            tooltip: 'Giriş yapmadan devam et',
            onPressed: _continueWithoutAccount,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch(_AuthPalette palette) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.controlSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: isLoginMode
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: constraints.maxWidth / 2,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: palette.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildModeItem(
                        label: 'Giriş Yap',
                        selected: isLoginMode,
                        onTap: () => _setMode(true),
                        palette: palette,
                      ),
                      _buildModeItem(
                        label: 'Kayıt Ol',
                        selected: !isLoginMode,
                        onTap: () => _setMode(false),
                        palette: palette,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModeItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required _AuthPalette palette,
  }) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            overlayColor: WidgetStatePropertyAll(
              palette.text.withValues(alpha: 0.06),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 190),
                style: GoogleFonts.inter(
                  color: selected ? palette.onAccent : palette.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(_AuthPalette palette) {
    return Column(
      key: ValueKey(isLoginMode ? 'login-form' : 'register-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isLoginMode) ...[
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Ad soyad',
            hint: 'Adın ve soyadın',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            palette: palette,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'E-posta',
          hint: 'ornek@email.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          palette: palette,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Şifre',
          hint: isLoginMode ? 'Şifren' : 'Güçlü bir şifre oluştur',
          icon: Icons.lock_outline_rounded,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: [
            isLoginMode ? AutofillHints.password : AutofillHints.newPassword,
          ],
          palette: palette,
          onSubmitted: (_) => _submitAuthForm(),
          suffixIcon: IconButton(
            tooltip: _isPasswordVisible ? 'Şifreyi gizle' : 'Şifreyi göster',
            onPressed: _isLoading
                ? null
                : () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
            ),
            color: palette.muted,
          ),
        ),
        if (isLoginMode) ...[
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: TextButton.styleFrom(
                foregroundColor: palette.text,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Şifremi unuttum',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    required Iterable<String> autofillHints,
    required _AuthPalette palette,
    required ValueChanged<String> onSubmitted,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final radius = BorderRadius.circular(14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: palette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              obscureText: obscureText,
              enabled: !_isLoading,
              autocorrect: false,
              cursorColor: palette.accent,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: palette.muted.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(icon, color: palette.muted, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 54,
                ),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: palette.glass,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.border),
                  borderRadius: radius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.accent, width: 1.4),
                  borderRadius: radius,
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.border),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(_AuthPalette palette) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _submitAuthForm,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          disabledBackgroundColor: palette.accent.withValues(alpha: 0.42),
          foregroundColor: palette.onAccent,
          disabledForegroundColor: palette.onAccent.withValues(alpha: 0.72),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 170),
          child: _isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.onAccent,
                  ),
                )
              : Row(
                  key: ValueKey(isLoginMode),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoginMode ? 'Giriş Yap' : 'Hesap Oluştur',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDivider(_AuthPalette palette) {
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'veya',
            style: GoogleFonts.inter(
              color: palette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.border, height: 1)),
      ],
    );
  }

  Widget _buildGoogleButton(_AuthPalette palette) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.glassStrong,
          foregroundColor: palette.text,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          overlayColor: palette.text.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/google_logo.png', width: 22, height: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Google ile devam et',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPalette {
  const _AuthPalette({
    required this.isDark,
    required this.scaffold,
    required this.text,
    required this.muted,
    required this.glass,
    required this.glassStrong,
    required this.controlSurface,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.shadow,
  });

  final bool isDark;
  final Color scaffold;
  final Color text;
  final Color muted;
  final Color glass;
  final Color glassStrong;
  final Color controlSurface;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color shadow;

  factory _AuthPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _AuthPalette(
      isDark: isDark,
      scaffold: isDark ? AppThemePalette.darkScaffold : const Color(0xFFF2F2F4),
      text: isDark ? AppThemePalette.darkText : const Color(0xFF111114),
      muted: isDark ? AppThemePalette.darkMuted : const Color(0xFF6E6E73),
      glass: isDark
          ? AppThemePalette.darkSurface.withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.72),
      glassStrong: isDark
          ? AppThemePalette.darkSurfaceStrong.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.84),
      controlSurface: isDark
          ? Colors.white.withValues(alpha: 0.065)
          : Colors.black.withValues(alpha: 0.035),
      border: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      accent: isDark ? AppThemePalette.darkText : const Color(0xFF111114),
      onAccent: isDark ? AppThemePalette.darkOnAccent : Colors.white,
      shadow: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
    );
  }
}
