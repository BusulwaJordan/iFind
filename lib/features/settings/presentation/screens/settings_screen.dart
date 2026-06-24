import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.deepGreen,
            title: Text(
              'Settings',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                    width: 2.5),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                backgroundImage: user?.avatarUrl != null
                                    ? NetworkImage(user!.avatarUrl!)
                                    : null,
                                child: user?.avatarUrl == null
                                    ? Text(
                                        user?.fullName.isNotEmpty == true
                                            ? user!.fullName[0].toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name / email / role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Guest',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user?.email ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      user?.role == UserRole.businessOwner
                                          ? 'Business Owner'
                                          : 'Customer',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),

                _SettingsSection(
                  title: 'My Account',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      iconColor: Colors.blue.shade600,
                      title: 'Edit Profile',
                      subtitle: 'Name, phone, and personal details',
                      onTap: () => context.push('/profile'),
                    ),
                    _SettingsTile(
                      icon: Icons.bookmark_rounded,
                      iconColor: Colors.amber.shade700,
                      title: 'My Favourites',
                      subtitle: 'View all saved businesses',
                      onTap: () => context.push('/favourites'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'Business Center',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.inbox_rounded,
                      iconColor: AppColors.primaryGreen,
                      title: 'Customer Inquiries',
                      subtitle: 'Respond to messages from customers',
                      onTap: () => context.push('/inquiries'),
                    ),
                    _SettingsTile(
                      icon: Icons.trending_up_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Leads Dashboard',
                      subtitle: 'B2B leads and posted customer needs',
                      onTap: () => context.push('/leads-dashboard'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'Preferences',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: Colors.orange,
                      title: 'Push Notifications',
                      subtitle: notificationsEnabled ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: notificationsEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .setEnabled(val),
                      ),
                      onTap: () => ref
                          .read(notificationSettingsProvider.notifier)
                          .setEnabled(!notificationsEnabled),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: Colors.teal,
                      title: 'Language',
                      subtitle: 'English (Uganda)',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'Support',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.help_rounded,
                      iconColor: Colors.blue.shade700,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact support',
                      onTap: () => context.push('/help'),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: Colors.grey.shade600,
                      title: 'Privacy Policy',
                      onTap: () async {
                        final uri = Uri.parse('https://ifind.ug/privacy');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SettingsSection(
                  title: 'App Info',
                  tiles: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) => _SettingsTile(
                        icon: Icons.info_rounded,
                        iconColor: Colors.blueGrey,
                        title: 'App Version',
                        subtitle: 'v${snapshot.data?.version ?? '1.0.0'}',
                        trailing: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Sign Out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section container ────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
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
                  offset: const Offset(0, 4),
                ),
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
      ),
    );
  }
}

// ── Single tile ──────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
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
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.darkText),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade300, size: 20),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
