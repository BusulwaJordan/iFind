import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interaction types matching the training dataset and database CHECK constraint.
enum InteractionType {
  view,
  searchClick,
  profileView,
  savedBusiness,
  inquirySent,
  reviewPosted;

  String get dbValue {
    switch (this) {
      case InteractionType.view:
        return 'view';
      case InteractionType.searchClick:
        return 'search_click';
      case InteractionType.profileView:
        return 'profile_view';
      case InteractionType.savedBusiness:
        return 'saved_business';
      case InteractionType.inquirySent:
        return 'inquiry_sent';
      case InteractionType.reviewPosted:
        return 'review_posted';
    }
  }
}

/// Service that logs B2C user interactions with businesses.
/// These interactions are used to train the B2C recommendation model (ALS).
class InteractionService {
  final SupabaseClient _client;

  InteractionService(this._client);

  /// Logs a user interaction with a business in the database.
  ///
  /// This runs asynchronously in the background. It is a fire-and-forget log
  /// to ensure UI performance is never blocked by interaction logging.
  Future<void> logInteraction({
    required String userId,
    required String businessId,
    required InteractionType type,
    String? sessionId,
    int? durationSeconds,
  }) async {
    try {
      debugPrint(
          'InteractionService: Logging ${type.dbValue} for user $userId on business $businessId...');

      await _client.from('interactions').insert({
        'user_id': userId,
        'business_id': businessId,
        'interaction_type': type.dbValue,
        if (sessionId != null) 'session_id': sessionId,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      });

      debugPrint('InteractionService: Successfully logged ${type.dbValue}.');
    } catch (e) {
      // Graceful failure — do not throw to avoid crashing/blocking the user interface
      debugPrint('InteractionService Error: Failed to log interaction: $e');
    }
  }
}
