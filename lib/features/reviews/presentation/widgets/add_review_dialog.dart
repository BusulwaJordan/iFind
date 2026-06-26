import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/interaction_service.dart';

class AddReviewDialog extends ConsumerStatefulWidget {
  final String businessId;
  const AddReviewDialog({super.key, required this.businessId});

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppToast.show(context, 'Please login to submit a review', type: ToastType.info);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(reviewRepositoryProvider).addReview(
      businessId: widget.businessId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) => AppToast.show(context, friendlyError(Exception(failure.message)), type: ToastType.error),
        (_) {
          // Refresh business data and reviews immediately
          ref.invalidate(businessProvider(widget.businessId));
          ref.invalidate(businessReviewsProvider(widget.businessId));
          ref.invalidate(featuredBusinessesProvider);
          ref.invalidate(nearbyBusinessesProvider);

          // Log B2C interaction
          ref.read(interactionServiceProvider).logInteraction(
            userId: user.id,
            businessId: widget.businessId,
            type: InteractionType.reviewPosted,
          );

          Navigator.pop(context);
          AppToast.show(context, 'Review submitted! Thank you.', type: ToastType.success);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate your experience', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Tell us more about your experience (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
        ),
      ],
    );
  }
}
