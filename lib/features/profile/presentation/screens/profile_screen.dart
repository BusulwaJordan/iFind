import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/widgets/app_drawer.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool initialEditing;
  const ProfileScreen({super.key, this.initialEditing = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _editing = false;
  bool _saving = false;
  Uint8List? _imageBytes;  // picked image bytes — works on web + mobile
  String? _imageExt;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl  = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _imageUrl  = user?.avatarUrl;
    _editing   = widget.initialEditing;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageExt = picked.mimeType?.split('/').last?.toLowerCase()
          ?? (picked.name.contains('.')
              ? picked.name.split('.').last.toLowerCase()
              : 'jpg');
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        AppToast.show(context, 'Not signed in — please log in again.', type: ToastType.error);
        return;
      }

      // Upload avatar separately so a storage failure doesn't block the text save.
      if (_imageBytes != null) {
        try {
          final ext = _imageExt ?? 'jpg';
          final path = 'avatars/$userId.$ext';
          await supabase.storage.from('profile_images').uploadBinary(
            path,
            _imageBytes!,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );
          // Cache-bust so Image.network fetches the new file instead of the old cached one.
          _imageUrl =
              '${supabase.storage.from('profile_images').getPublicUrl(path)}'
              '?v=${DateTime.now().millisecondsSinceEpoch}';
          // Update both sources so refreshCurrentUser always picks up the new URL.
          await supabase.from('users').update({
            'avatar_url': _imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
          await supabase.auth.updateUser(
            UserAttributes(data: {'avatar_url': _imageUrl}),
          );
          // Refresh OwnerAvatar widgets that cache this user's profile.
          ref.invalidate(userProfileProvider(userId));
        } catch (storageErr) {
          if (mounted) {
            AppToast.show(
              context,
              'Photo upload failed: $storageErr',
              type: ToastType.error,
            );
          }
        }
      }

      final phone = _phoneCtrl.text.trim();
      await supabase.from('users').update({
        'full_name': _nameCtrl.text.trim(),
        'phone': phone.isEmpty ? null : phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId).select().single();

      await ref.read(authProvider.notifier).refreshCurrentUser();
      if (mounted) {
        setState(() {
          _editing = false;
          _imageBytes = null;
          _imageExt = null;
        });
        AppToast.show(context, 'Profile updated', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, friendlyError(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const IFindLoadingPage();

    final canPop = Navigator.of(context).canPop();
    final initials = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';
    final joinDate = '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AppDrawer(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero ─────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHero(context, user, initials, canPop),
            ),

            // ── Content ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal info
                    _sectionLabel('Personal Information'),
                    const SizedBox(height: 14),
                    _field('Full Name', _nameCtrl, Icons.person_rounded,
                        enabled: _editing)
                        .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    _field('Phone Number', _phoneCtrl, Icons.phone_rounded,
                        enabled: _editing, type: TextInputType.phone)
                        .animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    _readonlyRow(Icons.email_rounded, 'Email', user.email)
                        .animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    _readonlyRow(Icons.calendar_today_rounded, 'Member Since', joinDate)
                        .animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),

                    // Edit / Save button
                    if (_editing) ...[
                      const SizedBox(height: 20),
                      _GradientBtn(
                        label: _saving ? 'Saving…' : 'Save Changes',
                        loading: _saving,
                        onTap: _saving ? null : _save,
                      ).animate().fadeIn(delay: 320.ms).scale(begin: const Offset(0.95, 0.95)),
                    ],

                    const SizedBox(height: 32),

                    // Quick links
                    _sectionLabel('My Account'),
                    const SizedBox(height: 14),
                    _actionTile(Icons.bookmark_rounded,    'Favourites',     Colors.amber.shade700,
                        () => context.push('/favourites'))
                        .animate().fadeIn(delay: 380.ms).slideX(begin: 0.1),
                    _actionTile(Icons.notifications_rounded, 'Notifications', Colors.blue,
                        () => context.push('/notifications'))
                        .animate().fadeIn(delay: 420.ms).slideX(begin: 0.1),
                    _actionTile(Icons.settings_rounded,    'Settings',        Colors.grey.shade600,
                        () => context.push('/settings'))
                        .animate().fadeIn(delay: 460.ms).slideX(begin: 0.1),
                    _actionTile(Icons.help_outline_rounded,'Help & Support',  AppColors.primaryGreen,
                        () => context.push('/help'))
                        .animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                    const SizedBox(height: 28),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: Text('Sign Out',
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 560.ms),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, user, String initials, bool canPop) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 16, 20, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003D2B), Color(0xFF006241), Color(0xFF0B7A5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(top: -20, right: -20,
              child: Container(width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar
                Row(
                  children: [
                    if (canPop)
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    if (!canPop)
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text('My Profile',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Edit / Cancel toggle
                    GestureDetector(
                      onTap: () {
                        if (_editing) {
                          // Cancel: revert unsaved changes
                          final user = ref.read(currentUserProvider);
                          setState(() {
                            _editing = false;
                            _imageBytes = null;
                            _imageExt = null;
                            _imageUrl = user?.avatarUrl;
                            _nameCtrl.text = user?.fullName ?? '';
                            _phoneCtrl.text = user?.phone ?? '';
                          });
                        } else {
                          setState(() => _editing = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _editing ? 'Cancel' : 'Edit',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // Avatar
                GestureDetector(
                  onTap: _editing ? _pickImage : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!) as ImageProvider
                            : (_imageUrl ?? user.avatarUrl) != null
                                ? NetworkImage(_imageUrl ?? user.avatarUrl!)
                                : null,
                        child: (_imageBytes == null && (_imageUrl ?? user.avatarUrl) == null)
                            ? Text(initials,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (_editing)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 14),
                        ),
                    ],
                  ),
                ).animate().scale(
                    delay: 100.ms, duration: 600.ms, curve: Curves.elasticOut,
                    begin: const Offset(0.7, 0.7)),

                const SizedBox(height: 14),

                Text(user.fullName,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900))
                    .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 4),

                Text(user.email,
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 13))
                    .animate().fadeIn(delay: 260.ms),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.1));
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = false, TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: enabled
                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                : Colors.grey.shade200),
        boxShadow: enabled
            ? [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.08),
                blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: type,
        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.darkText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
              color: enabled ? AppColors.primaryGreen : AppColors.lightText,
              fontSize: 12),
          prefixIcon: Icon(icon,
              color: enabled ? AppColors.primaryGreen : Colors.grey, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _readonlyRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.lightText)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 14, color: AppColors.darkText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        trailing:
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Gradient save button ──────────────────────────────────────────────────────

class _GradientBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientBtn(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.deepGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
