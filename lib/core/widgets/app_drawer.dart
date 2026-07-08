import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.48,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          _DrawerHeader(user: user),

          // ── Nav items ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (user?.role == UserRole.businessOwner) ...[
                  _DrawerItem(
                    icon: Icons.storefront_rounded,
                    label: 'My Shop Profile',
                    onTap: () => _push(context, '/shop-profile'),
                  ),
                  const Divider(height: 8, indent: 16, endIndent: 16),
                ],
                _DrawerItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'For You',
                  onTap: () => _go(context, '/for-you'),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  onTap: () => _push(context, '/notifications'),
                ),
                _DrawerItem(
                  icon: Icons.favorite_rounded,
                  label: 'Saved Businesses',
                  onTap: () => _push(context, '/favourites'),
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () => _push(context, '/settings'),
                ),
                _DrawerItem(
                  icon: Icons.help_rounded,
                  label: 'Help & Support',
                  onTap: () => _push(context, '/help'),
                ),
                const Divider(height: 12, indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  iconColor: Colors.red,
                  labelColor: Colors.red,
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  void _push(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }
}

// ── Drawer header ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final User? user;
  const _DrawerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Guest';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleLabel = user?.role == UserRole.businessOwner
        ? 'Business Owner'
        : user?.role == UserRole.manager
            ? 'Manager'
            : 'Customer';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003D2B), Color(0xFF006241), Color(0xFF0B7A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
            child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                ? Text(
                    initials,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          // Email
          Text(
            email,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              roleLabel,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual drawer item ────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryGreen;
    final textColor = labelColor ?? Theme.of(context).colorScheme.onSurface;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
