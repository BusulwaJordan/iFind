import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/constants/app_strings.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

class EmailConfirmationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends ConsumerState<EmailConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    _listenForVerification();
  }

  void _listenForVerification() {
    // The authProvider already listens to Supabase auth state changes
    // We just need to watch it in the build method
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for changes
    ref.listen<AsyncValue>(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          // User is verified and logged in - redirect to home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      });
    });

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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 80,
                      color: AppColors.primaryGreen,
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
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.registrationSuccess,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.checkEmailToVerify,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // Auto-redirect message
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'You\'ll be redirected automatically after verification',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.deepGreen,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Back to Login'),
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
    );
  }
}
