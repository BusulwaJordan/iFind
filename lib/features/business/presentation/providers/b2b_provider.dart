import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A B2B candidate paired with how compatible the hybrid model considers it —
/// the same score shown as a percentage on the match card, so the list order
/// always matches what's displayed.
class B2bMatchCandidate {
  final Business business;
  final double compatibilityScore;
  const B2bMatchCandidate(
      {required this.business, required this.compatibilityScore});
}

// Below this, the model considers the pairing "Poor Compatibility" (see
// B2bRecommendation.label) — not a real partnership candidate.
const _kMinViableCompatibility = 0.25;

/// The number of ranked candidates to pull from the hybrid backend before
/// applying local filters (not-connected / not-self-owned). Kept well above
/// the 10 we ultimately show since filtering can drop entries.
const _kBackendTopN = 50;

/// Nearby, not-already-connected businesses that the hybrid
/// recommendation backend (rule-based + content-based + collaborative
/// filtering, see `ifind_backend/main.py`) considers plausible partners for
/// [businessId], ranked highest-compatibility first. Keyed by the business's
/// stable text id so every screen that shows B2B matches for a business gets
/// the exact same list, instead of each call site independently computing
/// its own.
final b2bPartnerCandidatesProvider =
    FutureProvider.family<List<B2bMatchCandidate>, String>(
        (ref, businessId) async {
  final business = await ref.watch(businessProvider(businessId).future);
  if (business == null) return [];

  final service = ref.watch(b2bServiceProvider);
  final supabase = Supabase.instance.client;

  final recommendations =
      await service.getRecommendations(businessId, topN: _kBackendTopN);
  if (recommendations.isEmpty) return [];

  final chatsResp = await supabase
          .from('chats')
          .select('business_a_id, business_b_id')
          .eq('is_b2b', true)
          .or('business_a_id.eq.${business.id},business_b_id.eq.${business.id}')
      as List;

  final connectedIds = <String>{};
  for (final c in chatsResp) {
    final aId = c['business_a_id'] as String?;
    final bId = c['business_b_id'] as String?;
    if (aId != null && aId != business.id) connectedIds.add(aId);
    if (bId != null && bId != business.id) connectedIds.add(bId);
  }

  final repository = ref.watch(businessRepositoryProvider);
  final candidates = <B2bMatchCandidate>[];

  for (final rec in recommendations) {
    if (rec.finalScore <= _kMinViableCompatibility) continue;
    if (connectedIds.contains(rec.businessId)) continue;

    final candidateResult = await repository.getBusinessById(rec.businessId);
    final candidate = candidateResult.fold((failure) => null, (b) => b);
    if (candidate == null) continue;
    if (candidate.id == business.id) continue;
    if (candidate.ownerId == business.ownerId) continue;

    candidates.add(B2bMatchCandidate(
        business: candidate, compatibilityScore: rec.finalScore));
  }

  // The backend already returns results sorted by final_score descending;
  // re-sort defensively since local filtering doesn't change order but keeps
  // this provider's contract self-evident.
  candidates
      .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

  return candidates.take(10).toList();
});

/// Provider that computes B2B compatibility between the currently-viewed
/// business [targetBusiness] and the current user's own business [myBusiness],
/// by looking up [targetBusiness] within [myBusiness]'s ranked recommendation
/// list from the hybrid backend.
final b2bCompatibilityProvider = FutureProvider.family<B2bCompatibilityResult,
    ({Business myBusiness, Business targetBusiness})>((ref, args) async {
  final service = ref.watch(b2bServiceProvider);

  final recommendations =
      await service.getRecommendations(args.myBusiness.id, topN: _kBackendTopN);

  for (final rec in recommendations) {
    if (rec.businessId == args.targetBusiness.id) {
      return B2bCompatibilityResult(score: rec.finalScore);
    }
  }

  // Not among the ranked candidates (e.g. beyond the backend's max
  // distance, or no meaningful category/content overlap) — treat as no
  // compatibility rather than guessing.
  return const B2bCompatibilityResult(score: 0.0);
});

/// Thin result wrapper so callers (e.g. [_B2bCompatibilityCard]) keep using
/// the same score + label shape they did under the old Random Forest model.
class B2bCompatibilityResult {
  final double score;
  const B2bCompatibilityResult({required this.score});

  double get compatibilityScore => score;

  String get label {
    if (score >= 0.75) return 'High Compatibility';
    if (score >= 0.50) return 'Moderate Compatibility';
    if (score >= 0.25) return 'Low Compatibility';
    return 'Poor Compatibility';
  }

  String get percentageLabel => '${(score * 100).round()}% match';
}
