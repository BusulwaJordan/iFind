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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  UserRole _role = UserRole.customer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ─────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      AppToast.show(context, AppStrings.passwordsDontMatch,
          type: ToastType.error);
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final result = await ref.read(authProvider.notifier).register(
          email: email,
          password: password,
          fullName: _nameCtrl.text.trim(),
          role: _role,
          phone:
              _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );

    if (!mounted) return;

    if (result == null) {
      ref.read(pendingRegistrationProvider.notifier).state = null;
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (e, _) =>
            AppToast.show(context, e.toString(), type: ToastType.error),
      );
      return;
    }

    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
    if (!mounted) return;

    ref.read(pendingRegistrationProvider.notifier).state =
        PendingRegistration(email: email, password: password);
    AppToast.show(context, 'Account created! Check your email to confirm.',
        type: ToastType.success);
    context.go('/confirmation?email=${Uri.encodeComponent(email)}');
  }

  Future<void> _handleGoogleSignUp() async {
    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final authState = ref.read(authProvider);
    authState.whenOrNull(
      error: (e, _) =>
          AppToast.show(context, 'Google Sign-Up failed', type: ToastType.error),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authProvider).isLoading;
    final heroH = size.height * 0.30;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF064E3B),
        body: Stack(
          children: [
            // ── Background image ──────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/Color Gradient T-shirts Display.png',
                fit: BoxFit.cover,
              ).animate().fadeIn(duration: 700.ms),
            ),

            // ── Teal-green gradient overlay ───────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF064E3B).withValues(alpha: 0.90),
                      const Color(0xFF0D9488).withValues(alpha: 0.55),
                      const Color(0xFF064E3B).withValues(alpha: 0.97),
                    ],
                    stops: const [0.0, 0.38, 1.0],
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
                          top: MediaQuery.of(context).padding.top + 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.search_rounded,
                                size: 30, color: Colors.white),
                          )
                              .animate()
                              .scale(
                                  delay: 150.ms,
                                  duration: 650.ms,
                                  curve: Curves.elasticOut),
                          const SizedBox(height: 12),
                          Text(
                            'iFind',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 450.ms)
                              .slideY(begin: -0.2),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 350.ms, duration: 450.ms),
                          const SizedBox(height: 4),
                          Text(
                            'Join thousands of businesses & customers',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(delay: 420.ms, duration: 450.ms),
                        ],
                      ),
                    ),
                  ),

                  // ── White form card ───────────────────────────────────────
                  Container(
                    constraints:
                        BoxConstraints(minHeight: size.height * 0.73),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 56),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Heading
                            Text(
                              'Join iFind',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                                letterSpacing: -0.4,
                              ),
                            ).animate().fadeIn(delay: 300.ms, duration: 450.ms),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in your details to get started',
                              style: GoogleFonts.outfit(
                                  fontSize: 13, color: Colors.grey[500]),
                            ).animate().fadeIn(delay: 350.ms, duration: 450.ms),
                            const SizedBox(height: 28),

                            // ── Role toggle ───────────────────────────────
                            _RoleToggle(
                              selected: _role,
                              onChanged: isLoading
                                  ? null
                                  : (r) => setState(() => _role = r),
                            )
                                .animate()
                                .fadeIn(delay: 380.ms, duration: 450.ms)
                                .slideY(begin: 0.1),
                            const SizedBox(height: 24),

                            // Full name
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _field(
                                  label: AppStrings.fullName,
                                  icon: Icons.person_outline_rounded),
                              validator: Validators.validateName,
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 430.ms, duration: 400.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _field(
                                  label: AppStrings.email,
                                  icon: Icons.alternate_email_rounded),
                              validator: Validators.validateEmail,
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 490.ms, duration: 400.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 14),

                            // Phone (optional)
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: _field(
                                label:
                                    '${AppStrings.phoneNumber} (Optional)',
                                icon: Icons.phone_outlined,
                              ),
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 540.ms, duration: 400.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.next,
                              decoration: _field(
                                label: AppStrings.password,
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
                                .fadeIn(delay: 590.ms, duration: 400.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 14),

                            // Confirm password
                            TextFormField(
                              controller: _confirmPassCtrl,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  isLoading ? null : _handleRegister(),
                              decoration: _field(
                                label: AppStrings.confirmPassword,
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: Validators.validatePassword,
                              enabled: !isLoading,
                            )
                                .animate()
                                .fadeIn(delay: 640.ms, duration: 400.ms)
                                .slideX(begin: -0.06),
                            const SizedBox(height: 32),

                            // Create Account button
                            _CreateButton(
                              isLoading: isLoading,
                              onPressed: _handleRegister,
                            )
                                .animate()
                                .fadeIn(delay: 700.ms, duration: 400.ms)
                                .slideY(begin: 0.1),
                            const SizedBox(height: 24),

                            // OR divider
                            Row(
                              children: [
                                const Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text('OR',
                                      style: GoogleFonts.outfit(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ),
                                const Expanded(child: Divider(thickness: 1)),
                              ],
                            ).animate().fadeIn(delay: 750.ms, duration: 400.ms),
                            const SizedBox(height: 18),

                            // Google sign-up
                            _GoogleButton(
                              label: 'Sign up with Google',
                              onPressed:
                                  isLoading ? null : _handleGoogleSignUp,
                            ).animate().fadeIn(delay: 790.ms, duration: 400.ms),
                            const SizedBox(height: 28),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.alreadyHaveAccount,
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context.go('/login'),
                                  child: Text(
                                    '  Sign in',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 830.ms, duration: 400.ms),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.12,
                          delay: 250.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic)
                      .fadeIn(delay: 250.ms, duration: 500.ms),
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
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    );
  }
}

// ── Role toggle ───────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final UserRole selected;
  final void Function(UserRole)? onChanged;
  const _RoleToggle({required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          _RoleChip(
            label: 'Customer',
            icon: Icons.person_rounded,
            selected: selected == UserRole.customer,
            onTap: onChanged == null ? null : () => onChanged!(UserRole.customer),
          ),
          _RoleChip(
            label: 'Business Owner',
            icon: Icons.storefront_rounded,
            selected: selected == UserRole.businessOwner,
            onTap: onChanged == null
                ? null
                : () => onChanged!(UserRole.businessOwner),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const _RoleChip(
      {required this.label,
      required this.icon,
      required this.selected,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Account button ─────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _CreateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), AppColors.deepGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.40),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Create Account',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
