import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ifind/core/constants/ai_endpoints.dart';

/// A single ranked candidate returned by the hybrid recommender for a given
/// source business.
class B2bRecommendation {
  final String businessId;
  final String name;
  final String category;
  final String neighbourhood;
  final double distanceKm;
  final double ruleScore;
  final double contentScore;
  final double collaborativeScore;

  /// Average of whichever of the three sub-scores are non-zero/available —
  /// 0.0 (no compatibility) to 1.0 (perfect match).
  final double finalScore;

  /// Human-readable label derived from the score.
  String get label {
    if (finalScore >= 0.75) return 'High Compatibility';
    if (finalScore >= 0.50) return 'Moderate Compatibility';
    if (finalScore >= 0.25) return 'Low Compatibility';
    return 'Poor Compatibility';
  }

  /// Score as a percentage string, e.g. "87%"
  String get percentageLabel => '${(finalScore * 100).round()}% match';

  const B2bRecommendation({
    required this.businessId,
    required this.name,
    required this.category,
    required this.neighbourhood,
    required this.distanceKm,
    required this.ruleScore,
    required this.contentScore,
    required this.collaborativeScore,
    required this.finalScore,
  });

  factory B2bRecommendation.fromJson(Map<String, dynamic> json) {
    return B2bRecommendation(
      businessId: json['business_id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      neighbourhood: json['neighbourhood'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      ruleScore: (json['rule_score'] as num?)?.toDouble() ?? 0.0,
      contentScore: (json['content_score'] as num?)?.toDouble() ?? 0.0,
      collaborativeScore: (json['collaborative_score'] as num?)?.toDouble() ?? 0.0,
      finalScore: ((json['final_score'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
    );
  }
}

/// MODEL 3: B2B Hybrid Partner Recommender
///
/// Calls the standalone FastAPI hybrid recommendation backend deployed on
/// Render (see `ifind_backend/main.py`), which combines three signals for a
/// given source business against every other business:
/// - Rule-based: compatible category pairs (`category_connections` table)
///   within a max distance, scored by proximity.
/// - Content-based: TF-IDF + cosine similarity over category + neighbourhood.
/// - Collaborative filtering: cosine similarity over weighted user-business
///   interactions.
///
/// `final_score` is the average of whichever sub-scores are non-zero, and
/// results are pre-sorted descending by the backend.
class B2bService {
  final http.Client _httpClient;

  B2bService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Fetches ranked partner recommendations for [businessId].
  ///
  /// Returns an empty list on error rather than throwing, so callers can
  /// treat "no data" and "no matches" the same way.
  Future<List<B2bRecommendation>> getRecommendations(
    String businessId, {
    int topN = 10,
  }) async {
    try {
      debugPrint('B2bService: Fetching recommendations for $businessId (top $topN)...');

      final response = await _httpClient
          .get(Uri.parse(AiEndpoints.recommendForBusiness(businessId, topN: topN)))
          .timeout(AiEndpoints.coldStartTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final results = data
            .map((e) => B2bRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('B2bService: Got ${results.length} recommendations');
        return results;
      } else {
        debugPrint('B2bService Error: HTTP ${response.statusCode} — ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('B2bService Exception: $e');
      return [];
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
