import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/constants/app_strings.dart';
import 'package:ifind/core/utils/validators.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Login Screen with glassmorphism design
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        final authState = ref.read(authProvider);
        authState.whenOrNull(
          error: (error, _) {
            final errorStr = error.toString().toLowerCase();
            // Intercept email not confirmed error with a friendly, actionable dialog
            if (errorStr.contains('email not confirmed') ||
                errorStr.contains('email_not_confirmed')) {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              ref.read(pendingRegistrationProvider.notifier).state =
                  PendingRegistration(email: email, password: password);
              context.go('/confirmation?email=${Uri.encodeComponent(email)}');
            } else if (errorStr.contains('invalid login credentials') ||
                errorStr.contains('invalid credentials') ||
                errorStr.contains('user not found')) {
              _showCreateAccountDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          // On success, GoRouter intercepts auth state change and redirects automatically
        );
      }
    }
  }

  Future<void> _showCreateAccountDialog() async {
    final email = _emailController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.primaryGreen,
        ),
        title: const Text('Create your iFind account'),
        content: Text(
          email.isEmpty
              ? 'We could not find an account for those details. Register first so we can set up your customer or business owner profile.'
              : 'We could not find an account for $email. Register first so we can set up your customer or business owner profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try again'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/register');
            },
            icon: const Icon(Icons.app_registration_rounded),
            label: const Text('Register'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (mounted) {
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In failed: ${error.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.deepGreen,
              AppColors.primaryGreen,
              Color(0xFFF8FAFB),
              Color(0xFFF8FAFB),
            ],
            stops: [0, 0.2, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title
                    Hero(
                      tag: 'logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your discovery',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Login',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle:
                                    GoogleFonts.outfit(color: Colors.grey[600]),
                                prefixIcon: const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 20),
                              ),
                              validator: Validators.validateEmail,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle:
                                    GoogleFonts.outfit(color: Colors.grey[600]),
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: Validators.validatePassword,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 32),

                            // Login Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: AppColors.primaryGreen
                                      .withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'SIGN IN',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider with OR
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Google Sign-In Button
                            SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed:
                                    isLoading ? null : _handleGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.grey[300]!, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.network(
                                      'https://www.svgrepo.com/show/475656/google-color.svg',
                                      height: 22,
                                      width: 22,
                                      placeholderBuilder: (_) => const Icon(
                                          Icons.g_mobiledata,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.dontHaveAccount,
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.go('/register'),
                                  child: Text(
                                    AppStrings.register,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
