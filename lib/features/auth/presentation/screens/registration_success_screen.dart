import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';

/// Screen shown after successful registration, prompting user to verify email
class RegistrationSuccessScreen extends ConsumerWidget {
  final String email;
  final bool requiresConfirmation;

  const RegistrationSuccessScreen({
    super.key,
    required this.email,
    this.requiresConfirmation = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightGreen.withValues(alpha: 0.3),
              AppColors.white,
              AppColors.primaryGreen.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildSuccessIcon(),
                const SizedBox(height: 32),
                _buildMainContent(),
                const SizedBox(height: 24),
                _buildEmailCard(),
                const SizedBox(height: 32),
                _buildInstructionsCard(),
                const SizedBox(height: 32),
                _buildPrimaryButton(context),
                const SizedBox(height: 16),
                _buildSecondaryButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        size: 80,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Text(
          '🎉 Welcome to iFind!',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Registration Complete',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your account has been created successfully!\nNow let\'s verify your email address.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_rounded,
              color: AppColors.primaryGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Email Sent To',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What to Do Next:',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildInstructionStep(
                '1',
                'Check Your Email',
                'Look for a verification email from iFind in your inbox or spam folder.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                '2',
                'Click the Link',
                'Click the verification link in the email to confirm your email address.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                '3',
                'Automatic Redirect',
                'Once verified, you\'ll be automatically directed to the home page.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
      String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          if (requiresConfirmation) {
            context.go('/confirmation?email=${Uri.encodeComponent(email)}');
          } else {
            context.go('/');
          }
        },
        icon: Icon(
            requiresConfirmation ? Icons.mail_rounded : Icons.home_rounded),
        label: Text(requiresConfirmation
            ? 'Go to Email Verification'
            : 'Continue to Home'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: () {
          context.go('/register');
        },
        child: Text(
          'Use a Different Email',
          style: GoogleFonts.outfit(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
