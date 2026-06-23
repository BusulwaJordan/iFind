import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/services/proximity_service.dart';
import 'package:ifind/core/services/recommendation_service.dart';
import 'package:ifind/core/services/b2b_service.dart';
import 'package:ifind/core/services/interaction_service.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/core/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Proximity Service (MODEL 1 — PostGIS RPC, no ML)
// ---------------------------------------------------------------------------
final proximityServiceProvider = Provider<ProximityService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProximityService(client);
});

// ---------------------------------------------------------------------------
// Recommendation Service (MODEL 2 — B2C Collaborative Filtering)
// ---------------------------------------------------------------------------
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(
    supabaseAnonKey: ApiConstants.supabaseAnonKey,
  );
});

// ---------------------------------------------------------------------------
// B2B Service (MODEL 3 — Random Forest Regression)
// ---------------------------------------------------------------------------
final b2bServiceProvider = Provider<B2bService>((ref) {
  return B2bService(
    supabaseAnonKey: ApiConstants.supabaseAnonKey,
  );
});

// ---------------------------------------------------------------------------
// Interaction Service (B2C interactions logger)
// ---------------------------------------------------------------------------
final interactionServiceProvider = Provider<InteractionService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return InteractionService(client);
});
