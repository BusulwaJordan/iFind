import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notificationsEnabled =
        ref.watch(notificationSettingsProvider).value ?? true;
    final isBusinessOwner = user?.role == UserRole.businessOwner;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(36)),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 14, 20, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF003D2B),
                        Color(0xFF006241),
                        Color(0xFF0B7A5A)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative
                      Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 16),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text('Settings',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.settings_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 18),
                          Text(
                            'Manage your preferences\nand account settings',
                            style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14,
                                height: 1.5),
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sections ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Account
                    _Section(
                      title: 'My Account',
                      delay: 100,
                      tiles: [
                        _Tile(
                          icon: Icons.person_rounded,
                          color: Colors.blue.shade600,
                          title: 'Edit Profile',
                          subtitle: 'Name, phone and personal details',
                          onTap: () => context.push('/profile'),
                        ),
                        _Tile(
                          icon: Icons.bookmark_rounded,
                          color: Colors.amber.shade700,
                          title: 'My Favourites',
                          subtitle: 'View saved businesses',
                          onTap: () => context.push('/favourites'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Business Center (only for business owners)
                    if (isBusinessOwner) ...[
                      _Section(
                        title: 'Business Center',
                        delay: 200,
                        tiles: [
                          _Tile(
                            icon: Icons.inbox_rounded,
                            color: AppColors.primaryGreen,
                            title: 'Customer Inquiries',
                            subtitle: 'Respond to messages from customers',
                            onTap: () => context.push('/inquiries'),
                          ),
                          _Tile(
                            icon: Icons.trending_up_rounded,
                            color: Colors.deepPurple,
                            title: 'Leads Dashboard',
                            subtitle: 'B2B leads and customer needs',
                            onTap: () => context.push('/leads-dashboard'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Preferences
                    _Section(
                      title: 'Preferences',
                      delay: 300,
                      tiles: [
                        _Tile(
                          icon: Icons.notifications_rounded,
                          color: Colors.orange,
                          title: 'Push Notifications',
                          subtitle: notificationsEnabled
                              ? 'Enabled'
                              : 'Disabled',
                          trailing: Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: notificationsEnabled,
                              activeThumbColor: AppColors.primaryGreen,
                              onChanged: (val) => ref
                                  .read(notificationSettingsProvider.notifier)
                                  .setEnabled(val),
                            ),
                          ),
                          onTap: () => ref
                              .read(notificationSettingsProvider.notifier)
                              .setEnabled(!notificationsEnabled),
                        ),
                        _Tile(
                          icon: Icons.language_rounded,
                          color: Colors.teal,
                          title: 'Language',
                          subtitle: 'English (Uganda)',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Support
                    _Section(
                      title: 'Support',
                      delay: 400,
                      tiles: [
                        _Tile(
                          icon: Icons.help_rounded,
                          color: Colors.blue.shade700,
                          title: 'Help & Support',
                          subtitle: 'FAQs and contact support',
                          onTap: () => context.push('/help'),
                        ),
                        _Tile(
                          icon: Icons.privacy_tip_rounded,
                          color: Colors.grey.shade600,
                          title: 'Privacy Policy',
                          onTap: () async {
                            final uri = Uri.parse('https://ifind.ug/privacy');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // App Info
                    _Section(
                      title: 'App Info',
                      delay: 480,
                      tiles: [
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) => _Tile(
                            icon: Icons.info_rounded,
                            color: Colors.blueGrey,
                            title: 'App Version',
                            subtitle: 'v${snapshot.data?.version ?? '1.0.0'}',
                            trailing: const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Sign Out
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.redAccent),
                        label: Text('Sign Out',
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 560.ms),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  final int delay;
  const _Section(
      {required this.title, required this.tiles, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: tiles.asMap().entries.map((e) {
              final isLast = e.key == tiles.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 68, endIndent: 20),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.08);
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.darkText)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade300, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
