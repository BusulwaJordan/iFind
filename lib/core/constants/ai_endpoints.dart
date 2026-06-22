import 'package:ifind/core/constants/api_constants.dart';

/// Centralized configuration for iFind's custom AI model endpoints.
///
/// All three AI models run on Supabase infrastructure — no third-party
/// API keys needed. Model files (.pkl) are cached in Supabase Storage
/// and loaded on Edge Function cold-start.
class AiEndpoints {
  AiEndpoints._();

  // ---------------------------------------------------------------------------
  // Supabase Project Base URLs
  // ---------------------------------------------------------------------------
  static String get supabaseUrl => ApiConstants.supabaseUrl;

  // ---------------------------------------------------------------------------
  // Edge Function Endpoints
  // ---------------------------------------------------------------------------

  /// MODEL 2: B2C Collaborative Filtering (ALS via implicit library)
  /// POST {"user_id": "...", "n": 5}
  /// Returns: [{"business_id": "...", "name": "...", "category": "...", "score": 0.87}]
  static String get recommendBusinesses =>
      '$supabaseUrl/functions/v1/recommend-businesses';

  /// MODEL 3: B2B Random Forest Compatibility Matcher
  /// POST {"category_a": "Agriculture", "category_b": "Restaurant", "distance_km": 2.5}
  /// Returns: {"compatibility_score": 0.87}
  static String get b2bMatch => '$supabaseUrl/functions/v1/b2b-match';

  // ---------------------------------------------------------------------------
  // Supabase Storage — AI Model Files (Public bucket: ai_models)
  // ---------------------------------------------------------------------------
  static String get _storageBase =>
      '$supabaseUrl/storage/v1/object/public/ai_models';

  // B2C Model files
  static String get b2cModel => '$_storageBase/b2c_model.pkl';
  static String get userToIdx => '$_storageBase/user_to_idx.pkl';
  static String get businessToIdx => '$_storageBase/business_to_idx.pkl';
  static String get idxToBusiness => '$_storageBase/idx_to_business.pkl';
  static String get businessLookup => '$_storageBase/business_lookup.pkl';

  // B2B Model files
  static String get b2bModel => '$_storageBase/b2b_model.pkl';
  static String get encoderA => '$_storageBase/encoder_a.pkl';
  static String get encoderB => '$_storageBase/encoder_b.pkl';
  static String get b2bFeatures => '$_storageBase/b2b_features.pkl';

  // ---------------------------------------------------------------------------
  // Timeouts
  // ---------------------------------------------------------------------------

  /// Allow extra time for cold-start (model file download from Storage)
  static const Duration coldStartTimeout = Duration(seconds: 60);

  /// Warm requests (model already in memory)
  static const Duration warmTimeout = Duration(seconds: 5);
}
