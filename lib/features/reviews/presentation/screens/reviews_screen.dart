import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:ifind/features/reviews/presentation/widgets/add_review_dialog.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';

const _darkGreen = Color(0xFF0A5C36);

class ReviewsScreen extends ConsumerWidget {
  final String businessId;

  const ReviewsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));
    final currentUser = ref.watch(currentUserProvider);
    // Determine if the viewer owns this business
    final myBusinesses = ref.watch(myBusinessesProvider(currentUser?.id ?? '')).value ?? [];
    final isOwner = myBusinesses.any((b) => b.id == businessId);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5EA),
      appBar: AppBar(
        title: Text(
          'Reviews',
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
        actions: [
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
              onPressed: () => _showAddReviewDialog(context),
              tooltip: 'Write a review',
            ),
        ],
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Reviews Yet',
              message: 'Be the first to review this business!',
              icon: Icons.star_outline_rounded,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallRating(context, reviews),
                const SizedBox(height: 24),
                _buildRatingDistribution(context, reviews),
                const SizedBox(height: 24),
                Text(
                  'All Reviews',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                ...reviews.map((review) => _ReviewCard(
                      review: review,
                      isOwner: isOwner,
                      businessId: businessId,
                    )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading reviews: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(businessId: businessId),
    );
  }

  Widget _buildOverallRating(BuildContext context, List<Review> reviews) {
    final totalReviews = reviews.length;
    // rating is int in your entity, so we cast to double for calculation
    final averageRating = reviews.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) / totalReviews;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(5, (index) {
                  final starValue = averageRating - index;
                  IconData icon;
                  if (starValue >= 1) {
                    icon = Icons.star_rounded;
                  } else if (starValue > 0) {
                    icon = Icons.star_half_rounded;
                  } else {
                    icon = Icons.star_outline_rounded;
                  }
                  return Icon(icon, color: Colors.amber, size: 20);
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalReviews review${totalReviews > 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddReviewDialog(context),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Write Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(BuildContext context, List<Review> reviews) {
    final total = reviews.length;
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = reviews.where((r) => r.rating == i).length;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            final starCount = 5 - index;
            final count = distribution[starCount] ?? 0;
            final percentage = total > 0 ? (count / total) * 100 : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$starCount',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 0 ? _darkGreen : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Individual Review Card ──────────────────────────────────────
class _ReviewCard extends ConsumerStatefulWidget {
  final Review review;
  final bool isOwner;
  final String businessId;

  const _ReviewCard({
    required this.review,
    required this.isOwner,
    required this.businessId,
  });

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _showReplyField = false;
  bool _submitting = false;
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final result = await ref.read(reviewRepositoryProvider).addReply(
          reviewId: widget.review.id,
          reply: text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => AppToast.show(context, friendlyError(Exception(failure.message)), type: ToastType.error),
      (_) {
        ref.invalidate(businessReviewsProvider(widget.businessId));
        setState(() => _showReplyField = false);
        _replyCtrl.clear();
        AppToast.show(context, 'Reply posted', type: ToastType.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reviewer row ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: review.authorAvatarUrl != null
                    ? NetworkImage(review.authorAvatarUrl!)
                    : null,
                child: review.authorAvatarUrl == null
                    ? Text(
                        review.authorName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Anonymous User',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                              i < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 16,
                            )),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, y').format(review.createdAt),
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Reply button for owner (only if not already replied)
              if (widget.isOwner && review.ownerReply == null)
                TextButton.icon(
                  onPressed: () => setState(() => _showReplyField = !_showReplyField),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(_showReplyField ? 'Cancel' : 'Reply',
                      style: GoogleFonts.outfit(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: _darkGreen),
                ),
            ],
          ),

          // ── Comment ──
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ],

          // ── Existing owner reply ──
          if (review.ownerReply != null && review.ownerReply!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _darkGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 14, color: _darkGreen),
                      const SizedBox(width: 6),
                      Text('Owner response',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _darkGreen)),
                      if (review.repliedAt != null) ...[
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, y').format(review.repliedAt!),
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.ownerReply!,
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[800], height: 1.4)),
                ],
              ),
            ),
          ],

          // ── Reply input field (owner only, when toggled) ──
          if (_showReplyField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _replyCtrl,
              maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write your response...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _darkGreen, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _submitting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Post Reply', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}