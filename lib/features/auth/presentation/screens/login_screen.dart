import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/constants/app_strings.dart';
import 'package:ifind/core/utils/validators.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _loginError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic ────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final errorMsg = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (!mounted) return;
    if (errorMsg != null) {
      final msg = errorMsg.toLowerCase();
      if (msg.contains('email not confirmed') ||
          msg.contains('email_not_confirmed')) {
        final email = _emailCtrl.text.trim();
        ref.read(pendingRegistrationProvider.notifier).state =
            PendingRegistration(email: email, password: _passCtrl.text);
        context.go('/confirmation?email=${Uri.encodeComponent(email)}');
      } else {
        setState(() => _loginError = 'Incorrect email or password. Please try again.');
      }
    } else {
      setState(() => _loginError = null);
    }
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final authState = ref.read(authProvider);
    authState.whenOrNull(
      error: (e, _) =>
          AppToast.show(context, 'Google Sign-In failed', type: ToastType.error),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show welcome toast when login succeeds.
    ref.listen<AsyncValue<User?>>(authProvider, (previous, current) {
      if (previous?.isLoading != true) return;
      current.whenOrNull(
        data: (user) {
          if (user != null) {
            AppToast.show(
              context,
              'Welcome back, ${user.fullName.split(' ').first}! 👋',
              type: ToastType.success,
            );
          }
        },
      );
    });

    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authProvider).isLoading;
    final heroH = size.height * 0.42;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.deepGreen,
        body: Stack(
          children: [
            // ── Full-screen background image ──────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/Modern Workspace Setup.png',
                fit: BoxFit.cover,
              ).animate().fadeIn(duration: 700.ms),
            ),

            // ── Green gradient overlay ────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF064E3B).withValues(alpha: 0.92),
                      const Color(0xFF10B981).withValues(alpha: 0.50),
                      const Color(0xFF064E3B).withValues(alpha: 0.96),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero section
                  SizedBox(
                    height: heroH,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.search_rounded,
                                size: 36, color: Colors.white),
                          )
                              .animate()
                              .scale(
                                  delay: 200.ms,
                                  duration: 700.ms,
                                  curve: Curves.elasticOut),
                          const SizedBox(height: 14),
                          Text(
                            'iFind',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(begin: -0.25),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 420.ms, duration: 500.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue your discovery',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 520.ms, duration: 500.ms),
                        ],
                      ),
                    ),
                  ),

                  // ── White form card ───────────────────────────────────
                  Container(
                    constraints:
                        BoxConstraints(minHeight: size.height * 0.65),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card heading
                            Text(
                              'Sign In',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                                letterSpacing: -0.4,
                              ),
                            ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your credentials to access your account',
                              style: GoogleFonts.outfit(
                                  fontSize: 13, color: Colors.grey[500]),
                            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                            const SizedBox(height: 32),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_loginError != null) setState(() => _loginError = null);
                              },
                              decoration: _field(
                                  label: 'Email Address',
                                  icon: Icons.alternate_email_rounded),
                              validator: Validators.validateEmail,
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 460.ms, duration: 450.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                if (_loginError != null) setState(() => _loginError = null);
                              },
                              onFieldSubmitted: (_) =>
                                  isLoading ? null : _handleLogin(),
                              decoration: _field(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: Validators.validatePassword,
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 540.ms, duration: 450.ms)
                                .slideX(begin: -0.06),

                            // Error banner
                            if (_loginError != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE53935),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_rounded,
                                        color: Color(0xFFE53935), size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFB71C1C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Sign In button
                            _SignInButton(
                              isLoading: isLoading,
                              onPressed: _handleLogin,
                            )
                                .animate()
                                .fadeIn(delay: 620.ms, duration: 450.ms)
                                .slideY(begin: 0.12),
                            const SizedBox(height: 24),

                            // OR divider
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text('OR',
                                      style: GoogleFonts.outfit(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ),
                                const Expanded(
                                    child: Divider(thickness: 1)),
                              ],
                            )
                                .animate()
                                .fadeIn(delay: 680.ms, duration: 400.ms),
                            const SizedBox(height: 20),

                            // Google button
                            _GoogleButton(
                              label: 'Continue with Google',
                              onPressed:
                                  isLoading ? null : _handleGoogleLogin,
                            )
                                .animate()
                                .fadeIn(delay: 720.ms, duration: 400.ms),
                            const SizedBox(height: 28),

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.dontHaveAccount,
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context.go('/register'),
                                  child: Text(
                                    '  Create one',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(delay: 780.ms, duration: 400.ms),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.12,
                          delay: 280.ms,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic)
                      .fadeIn(delay: 280.ms, duration: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _field({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF0FDF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}

// ── Sign In button ────────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.deepGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.network(
              'https://www.svgrepo.com/show/475656/google-color.svg',
              height: 20,
              width: 20,
              placeholderBuilder: (_) =>
                  const Icon(Icons.g_mobiledata, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
