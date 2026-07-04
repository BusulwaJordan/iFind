import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';

// Dark green constant matching your dashboard
const _darkGreen = Color(0xFF0A5C36);

class B2bMatchesScreen extends ConsumerWidget {
  const B2bMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
    final business = myBusinessesAsync.value?.firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5EA), // Light green background
      appBar: AppBar(
        title: Text(
          'B2B Matches',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _darkGreen,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Business Found',
              message: 'You need to create a business to see B2B matches.',
              icon: Icons.business_center_outlined,
            );
          }

          if (business == null) {
            return const Center(child: Text('No business linked to your account.'));
          }

          final candidatesAsync = ref.watch(b2bPartnerCandidatesProvider(business.id));

          return candidatesAsync.when(
            data: (candidates) {
              if (candidates.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No B2B Matches Yet',
                  message: 'We\'ll suggest potential partners as more businesses join the platform.',
                  icon: Icons.handshake_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(b2bPartnerCandidatesProvider(business.id));
                },
                color: _darkGreen,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return _B2bMatchCard(
                      business: business,
                      partner: candidate.business,
                      compatibilityScore: candidate.compatibilityScore,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _B2bMatchCard extends ConsumerStatefulWidget {
  final Business business;
  final Business partner;
  final double compatibilityScore;

  const _B2bMatchCard({
    required this.business,
    required this.partner,
    required this.compatibilityScore,
  });

  @override
  ConsumerState<_B2bMatchCard> createState() => _B2bMatchCardState();
}

class _B2bMatchCardState extends ConsumerState<_B2bMatchCard> {
  bool _isConnecting = false;

  Future<void> _onConnect() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      AppToast.show(context, 'Please log in to connect.', type: ToastType.warning);
      return;
    }

    final introMessage = await _showIntroDialog();
    if (introMessage == null) return; // user cancelled

    setState(() => _isConnecting = true);
    try {
      final chat = await ref
          .read(chatRemoteDataSourceProvider)
          .getOrCreateB2BChat(
            businessId: widget.business.id,
            partnerBusinessId: widget.partner.id,
          );

      if (introMessage.isNotEmpty) {
        await ref.read(chatRemoteDataSourceProvider).sendMessage(
          chatId: chat.id,
          senderId: currentUser.id,
          content: introMessage,
        );
      }

      ref.invalidate(b2bPartnerCandidatesProvider(widget.business.id));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chat: chat,
              otherPartyName: widget.partner.name,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('B2B connect error: $e');
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<String?> _showIntroDialog() async {
    final controller = TextEditingController(
      text:
          'Hi! I\'m ${widget.business.name}. I think we could work well together — would you be open to connecting?',
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connect with',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
            ),
            Text(
              widget.partner.name,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send an introduction message:',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Send & Connect', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Partner logo
          Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _darkGreen.withValues(alpha: 0.1),
              border: Border.all(color: _darkGreen.withValues(alpha: 0.2)),
            ),
            child: ClipOval(
              child: widget.partner.logoUrl != null
                  ? Image.network(
                      widget.partner.logoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          widget.partner.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.partner.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                    ),
            ),
          ),
          // Partner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partner.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.partner.category.name,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      widget.partner.distance != null
                          ? '${widget.partner.distance!.toStringAsFixed(1)} km'
                          : 'Unknown',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.handshake_outlined, size: 13, color: Colors.amber[700]),
                    const SizedBox(width: 3),
                    Text(
                      '${(widget.compatibilityScore * 100).toInt()}% match',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Connect button
          SizedBox(
            width: 90,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _darkGreen.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Connect',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}