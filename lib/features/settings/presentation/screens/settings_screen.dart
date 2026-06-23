import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final notificationsEnabled =
        ref.watch(notificationSettingsProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // User Profile Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryGreen,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.fullName[0] ?? 'U',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Guest',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const _SectionHeader(title: 'My Account'),
          _SettingsTile(
            icon: Icons.person_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your name, phone and details',
            onTap: () => context.push('/profile'),
          ),
          _SettingsTile(
            icon: Icons.bookmark_rounded,
            title: 'My Favourites',
            subtitle: 'View saved businesses',
            onTap: () => context.push('/favourites'),
          ),

          const SizedBox(height: 8),
          const _SectionHeader(title: 'Business Center'),
          _SettingsTile(
            icon: Icons.inbox_rounded,
            title: 'Customer Inquiries',
            subtitle: 'View and respond to customer messages',
            onTap: () => context.push('/inquiries'),
          ),
          _SettingsTile(
            icon: Icons.dashboard_outlined,
            title: 'Leads Dashboard',
            subtitle: 'Open B2B leads and customer needs',
            onTap: () => context.push('/leads-dashboard'),
          ),

          const SizedBox(height: 8),
          const _SectionHeader(title: 'General'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .setEnabled(!notificationsEnabled);
            },
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (val) {
                ref.read(notificationSettingsProvider.notifier).setEnabled(val);
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),

          const _SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQ and contact support',
            onTap: () => context.push('/help'),
          ),
          _SettingsTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () async {
              final uri = Uri.parse('https://ifind.ug/privacy');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),

          const _SectionHeader(title: 'App Info'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: snapshot.data?.version ?? '1.0.0',
              );
            },
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkText),
      title:
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
