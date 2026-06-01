import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ozet_app/screens/home_screen.dart';
import 'package:ozet_app/widgets/app_feedback.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const Color _accentBlue = Color(0xFF9EC8ED);
  static const Color _primaryNavy = Color(0xFF0A2342);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        e.message ?? 'Firebase hatası oluştu.',
        type: AppFeedbackType.error,
      );
    } catch (e) {
      _showSnackBar(
        'Google ile giriş başarısız. Lütfen tekrar deneyin.',
        type: AppFeedbackType.error,
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

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential;

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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on FirebaseAuthException catch (err) {
      _showSnackBar(
        err.message ?? 'Giriş işlemi başarısız.',
        type: AppFeedbackType.error,
      );
    } catch (_) {
      _showSnackBar(
        'Beklenmeyen bir hata oluştu.',
        type: AppFeedbackType.error,
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
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar(
        'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
        type: AppFeedbackType.success,
      );
    } on FirebaseAuthException catch (err) {
      _showSnackBar(
        err.message ?? 'Şifre sıfırlama gönderilemedi.',
        type: AppFeedbackType.error,
      );
    } catch (_) {
      _showSnackBar(
        'Şifre sıfırlama gönderilemedi.',
        type: AppFeedbackType.error,
      );
    }
  }

  void _showSnackBar(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    if (!mounted) return;
    AppFeedback.show(context, message, type: type);
  }

  void _setMode(bool loginMode) {
    if (isLoginMode == loginMode) return;
    setState(() => isLoginMode = loginMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? const Color(0xFF121212) : Colors.white;
    final Color surface = isDark ? const Color(0xFF1D1D1D) : Colors.white;
    final Color inputFill = isDark
        ? const Color(0xFF262626)
        : const Color(0xFFF4F7FA);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color borderColor = isDark
        ? Colors.grey[800]!
        : const Color(0xFFE4EAF0);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrandHeader(textColor, mutedColor, isDark),
                  const SizedBox(height: 30),
                  _buildModeSwitch(surface, inputFill, textColor, mutedColor),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Column(
                      key: ValueKey(isLoginMode),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isLoginMode) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Ad Soyad',
                            hint: 'Adınız Soyadınız',
                            icon: Icons.person_outline,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            fillColor: inputFill,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: 'E-posta',
                          hint: 'ornek@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          fillColor: inputFill,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          hint: 'Şifreniz',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          fillColor: inputFill,
                          borderColor: borderColor,
                          suffixIcon: IconButton(
                            tooltip: _isPasswordVisible
                                ? 'Şifreyi gizle'
                                : 'Şifreyi göster',
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: mutedColor,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                        if (isLoginMode) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              child: Text(
                                'Şifremi unuttum',
                                style: GoogleFonts.kadwa(
                                  color: _accentBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 22),
                      ],
                    ),
                  ),
                  _buildPrimaryButton(),
                  const SizedBox(height: 22),
                  _buildDivider(mutedColor),
                  const SizedBox(height: 22),
                  _buildGoogleButton(textColor, inputFill, borderColor),
                  const SizedBox(height: 12),
                  _buildSkipButton(mutedColor),
                  const SizedBox(height: 26),
                  _buildBottomModeHint(mutedColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(Color textColor, Color mutedColor, bool isDark) {
    return Column(
      children: [
        ColorFiltered(
          colorFilter: isDark
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: Image.asset('assets/logo_ozet.png', width: 142),
        ),
        const SizedBox(height: 22),
        Text(
          isLoginMode ? 'Tekrar hoş geldin' : 'Özet hesabını oluştur',
          textAlign: TextAlign.center,
          style: GoogleFonts.kadwa(
            color: textColor,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gündemi kısa, sakin ve net takip et.',
          textAlign: TextAlign.center,
          style: GoogleFonts.kadwa(
            color: mutedColor,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // Giriş/Kayıt geçişini tek parça kayan segment bar olarak gösterir.
  Widget _buildModeSwitch(
    Color surface,
    Color inputFill,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: isLoginMode
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildModeItem(
                label: 'Giriş Yap',
                selected: isLoginMode,
                onTap: () => _setMode(true),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              _buildModeItem(
                label: 'Kayıt Ol',
                selected: !isLoginMode,
                onTap: () => _setMode(false),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _accentBlue.withValues(alpha: 0.08),
          highlightColor: _accentBlue.withValues(alpha: 0.05),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: GoogleFonts.kadwa(
              color: selected ? textColor : mutedColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            child: SizedBox.expand(child: Center(child: Text(label))),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color mutedColor,
    required Color fillColor,
    required Color borderColor,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kadwa(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: !_isLoading,
          style: GoogleFonts.kadwa(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.kadwa(color: mutedColor, fontSize: 14),
            prefixIcon: Icon(icon, color: mutedColor, size: 21),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _accentBlue, width: 1.8),
              borderRadius: BorderRadius.circular(14),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAuthForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryNavy,
          disabledBackgroundColor: _primaryNavy.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  key: ValueKey(isLoginMode),
                  isLoginMode ? 'Giriş Yap' : 'Hesap Oluştur',
                  style: GoogleFonts.kadwa(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider(Color mutedColor) {
    return Row(
      children: [
        Expanded(child: Divider(color: mutedColor.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'veya',
            style: GoogleFonts.kadwa(color: mutedColor, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: mutedColor.withValues(alpha: 0.25))),
      ],
    );
  }

  Widget _buildGoogleButton(
    Color textColor,
    Color fillColor,
    Color borderColor,
  ) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: fillColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/google_logo.png', width: 24, height: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Google ile devam et',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kadwa(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Geçici geliştirme kısayolu: Firebase auth yapmadan ana sayfaya geçer.
  Widget _buildSkipButton(Color mutedColor) {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
      child: Text(
        'Şimdilik giriş yapmadan devam et',
        textAlign: TextAlign.center,
        style: GoogleFonts.kadwa(
          color: mutedColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomModeHint(Color mutedColor) {
    return TextButton(
      onPressed: _isLoading ? null : () => _setMode(!isLoginMode),
      child: Text(
        isLoginMode
            ? 'Hesabın yok mu? Kayıt ol'
            : 'Zaten hesabın var mı? Giriş yap',
        textAlign: TextAlign.center,
        style: GoogleFonts.kadwa(
          color: _accentBlue,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
