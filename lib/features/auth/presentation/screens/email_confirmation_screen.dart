import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';

class EmailConfirmationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState
    extends ConsumerState<EmailConfirmationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isResending = false;
  bool _verified = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkVerification();
    });
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    if (_verified || !mounted) return;

    if (ref.read(currentUserProvider) != null) {
      _onVerified();
      return;
    }

    final pending = ref.read(pendingRegistrationProvider);
    if (pending == null) return;

    final success =
        await ref.read(authProvider.notifier).tryLoginAfterVerification(
              email: pending.email,
              password: pending.password,
            );

    if (success && mounted) {
      setState(() => _verified = true);
      _pollTimer?.cancel();
      ref.read(pendingRegistrationProvider.notifier).state = null;
      context.go('/');
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);

    final email = widget.email.isNotEmpty
        ? widget.email
        : ref.read(pendingRegistrationProvider)?.email ?? '';

    if (email.isEmpty) {
      setState(() => _isResending = false);
      return;
    }

    final error =
        await ref.read(authProvider.notifier).resendConfirmationEmail(email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email resent! Check your inbox.'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );

    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _onVerified() {
    if (_verified) return;
    setState(() => _verified = true);
    _pollTimer?.cancel();
    ref.read(pendingRegistrationProvider.notifier).state = null;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email.isNotEmpty
        ? widget.email
        : ref.watch(pendingRegistrationProvider)?.email ?? '';

    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) _onVerified();
      });
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepGreen.withValues(alpha: 0.08),
              AppColors.white,
              AppColors.primaryGreen.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAnimatedIcon(),
                const SizedBox(height: 28),
                _buildTitle(),
                const SizedBox(height: 24),
                _buildEmailCard(displayEmail),
                const SizedBox(height: 28),
                _buildStepsCard(),
                const SizedBox(height: 24),
                _buildStatusIndicator(),
                const SizedBox(height: 24),
                _buildResendButton(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 20),
                _buildAlreadyVerifiedSection(context),
                const SizedBox(height: 16),
                _buildWrongEmailLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.mark_email_unread_rounded,
          size: 68,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Check Your Email',
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a confirmation link to your Gmail or email app. Tap it to finish.',
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

  Widget _buildEmailCard(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.email_rounded,
                color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification email sent to',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isNotEmpty ? email : 'your email address',
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

  Widget _buildStepsCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What to do next:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(
                icon: Icons.inbox_rounded,
                color: const Color(0xFF6366F1),
                title: 'Open Gmail or your inbox',
                subtitle: 'Look for an email from iFind. Check spam if needed.',
              ),
              _buildStepConnector(),
              _buildStep(
                icon: Icons.touch_app_rounded,
                color: const Color(0xFF0EA5E9),
                title: 'Click the confirmation link',
                subtitle: 'Tap "Confirm Email" in the email we sent you.',
              ),
              _buildStepConnector(),
              _buildStep(
                icon: Icons.login_rounded,
                color: AppColors.primaryGreen,
                title: 'Go straight to iFind',
                subtitle:
                    'After confirmation, we\'ll take you to the home page.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
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

  Widget _buildStepConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primaryGreen, size: 22),
            const SizedBox(width: 10),
            Text(
              'Email verified! Taking you home...',
              style: GoogleFonts.outfit(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Waiting for email verification...',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    final canResend = _resendCooldown == 0 && !_isResending;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: canResend ? _resendEmail : null,
        icon: _isResending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(
          _resendCooldown > 0
              ? 'Resend in ${_resendCooldown}s'
              : 'Resend Confirmation Email',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Already verified?',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildAlreadyVerifiedSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.login_rounded),
        label: Text(
          'Go to Sign In',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.deepGreen.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildWrongEmailLink(BuildContext context) {
    return TextButton(
      onPressed: () {
        ref.read(pendingRegistrationProvider.notifier).state = null;
        context.go('/register');
      },
      child: Text(
        'Wrong email? Register again',
        style: GoogleFonts.outfit(
          color: Colors.grey[500],
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
