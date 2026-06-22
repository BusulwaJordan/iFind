import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';

/// Shown after the user clicks the email confirmation link.
/// Auto-redirects to login after 4 seconds, or user can tap "Sign In Now".
class EmailVerifiedScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerifiedScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerifiedScreen> createState() =>
      _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends ConsumerState<EmailVerifiedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Timer? _autoRedirectTimer;
  int _countdown = 4;

  @override
  void initState() {
    super.initState();

    // Scale-in animation for the checkmark
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    // Auto-redirect to home after 2 seconds
    _autoRedirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _autoRedirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepGreen.withValues(alpha: 0.1),
              AppColors.white,
              AppColors.primaryGreen.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                _buildAnimatedCheckmark(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 24),
                _buildEmailBadge(),
                const SizedBox(height: 32),
                _buildInfoCard(),
                const SizedBox(height: 40),
                _buildCountdownButton(context),
                const SizedBox(height: 16),
                _buildSkipLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryGreen.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          size: 90,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          '✨ You\'re Verified!',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your email has been confirmed.\nWelcome to iFind!',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded,
              color: AppColors.primaryGreen, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.email.isNotEmpty ? widget.email : 'Your account',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.deepGreen,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFeature(
                Icons.search_rounded,
                'Discover Local Businesses',
                'Find shops, services, and products near you.',
                const Color(0xFF6366F1),
              ),
              const SizedBox(height: 16),
              _buildFeature(
                Icons.auto_awesome_rounded,
                'AI-Powered Recommendations',
                'Get personalized suggestions tailored to your needs.',
                const Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 16),
              _buildFeature(
                Icons.handshake_rounded,
                'Connect & Collaborate',
                'Chat with businesses and explore B2B opportunities.',
                AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
      IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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

  Widget _buildCountdownButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          _autoRedirectTimer?.cancel();
          context.go('/');
        },
        icon: const Icon(Icons.home_rounded, size: 22),
        label: Text(
          _countdown > 0 ? 'Go to Home  ($_countdown)' : 'Go to Home',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
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

  Widget _buildSkipLink(BuildContext context) {
    return TextButton(
      onPressed: () {
        _autoRedirectTimer?.cancel();
        context.go('/');
      },
      child: Text(
        'Continue to Home',
        style: GoogleFonts.outfit(
          color: Colors.grey[500],
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
