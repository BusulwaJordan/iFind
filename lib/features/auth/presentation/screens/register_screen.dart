import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/constants/app_strings.dart';
import 'package:ifind/core/utils/validators.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';

/// Registration Screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.passwordsDontMatch),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await ref.read(authProvider.notifier).register(
            email: email,
            password: password,
            fullName: _fullNameController.text.trim(),
            role: _selectedRole,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      if (!mounted) return;

      if (result == null) {
        ref.read(pendingRegistrationProvider.notifier).state = null;

        final authState = ref.read(authProvider);
        authState.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
        return;
      }

      // Ensure onboarding is complete
      await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();

      if (!mounted) return;

      ref.read(pendingRegistrationProvider.notifier).state =
          PendingRegistration(email: email, password: password);
      context.go('/confirmation?email=${Uri.encodeComponent(email)}');
    }
  }

  Future<void> _handleGoogleSignUp() async {
    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (mounted) {
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-Up failed: ${error.toString()}'),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightGreen.withValues(alpha: 0.3),
              AppColors.white,
              AppColors.primaryGreen.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      AppStrings.register,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 32),

                    // Glassmorphism Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Full Name
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.fullName,
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: Validators.validateName,
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.email,
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: Validators.validateEmail,
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: 16),

                                // Phone (optional)
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText:
                                        '${AppStrings.phoneNumber} (Optional)',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: 16),

                                // Role Selection
                                DropdownButtonFormField<UserRole>(
                                  initialValue: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.selectRole,
                                    prefixIcon: Icon(Icons.work_outline),
                                  ),
                                  items: UserRole.values.map((role) {
                                    return DropdownMenuItem(
                                      value: role,
                                      child: Text(role.displayName),
                                    );
                                  }).toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedRole = value!;
                                          });
                                        },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.password,
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
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
                                const SizedBox(height: 16),

                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.confirmPassword,
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: Validators.validatePassword,
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
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
                                            'CREATE ACCOUNT',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Divider
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

                                // Google Sign-Up Button
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed:
                                        isLoading ? null : _handleGoogleSignUp,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey[300]!, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          'Sign up with Google',
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
                                const SizedBox(height: 16),

                                // Login Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.alreadyHaveAccount,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => context.go('/login'),
                                      child: const Text(AppStrings.login),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
