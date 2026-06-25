import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
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
                _buildRatingDistribution(reviews),
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
                ...reviews.map((review) => _ReviewCard(review: review)).toList(),
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
        color: Colors.white,
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

  Widget _buildRatingDistribution(List<Review> reviews) {
    final total = reviews.length;
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = reviews.where((r) => r.rating == i).length;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  Icon(Icons.star_rounded, color: Colors.amber, size: 16),
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
class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              // Avatar using authorAvatarUrl from your entity
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
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, y').format(review.createdAt),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment (nullable in your entity)
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              review.comment!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          // Note: Your Review entity doesn't have a "reply" field,
          // so that section has been removed.
        ],
      ),
    );
  }
}