import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ifind/core/constants/ai_endpoints.dart';

/// Result from the B2B compatibility model.
class B2bCompatibilityResult {
  /// Score between 0.0 (no compatibility) and 1.0 (perfect match).
  final double compatibilityScore;

  /// Human-readable label derived from the score.
  String get label {
    if (compatibilityScore >= 0.75) return 'High Compatibility';
    if (compatibilityScore >= 0.50) return 'Moderate Compatibility';
    if (compatibilityScore >= 0.25) return 'Low Compatibility';
    return 'Poor Compatibility';
  }

  /// Score as a percentage string, e.g. "87%"
  String get percentageLabel => '${(compatibilityScore * 100).round()}% match';

  const B2bCompatibilityResult({required this.compatibilityScore});

  factory B2bCompatibilityResult.fromJson(Map<String, dynamic> json) {
    final raw = json['compatibility_score'] ?? json['score'] ?? 0.0;
    return B2bCompatibilityResult(
      compatibilityScore: (raw as num).toDouble().clamp(0.0, 1.0),
    );
  }

  @override
  String toString() =>
      'B2bCompatibilityResult(score: $compatibilityScore, label: $label)';
}

/// MODEL 3: B2B Random Forest Compatibility Matcher
///
/// Calls the `b2b-match` Supabase Edge Function, which loads a pre-trained
/// RandomForestRegressor from Supabase Storage.
///
/// The model was trained on `b2b_matches_clean.csv` using:
/// - distance_km: distance between the two businesses
/// - same_category: binary flag (1 = same category)
/// - encoded categories for both business A and business B
///
/// Input: two business categories + distance → Output: float 0–1
class B2bService {
  final http.Client _httpClient;
  final String _supabaseAnonKey;

  B2bService({
    http.Client? httpClient,
    required String supabaseAnonKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _supabaseAnonKey = supabaseAnonKey;

  /// Predicts how compatible [categoryA] and [categoryB] businesses are
  /// given the [distanceKm] between them.
  ///
  /// Returns a [B2bCompatibilityResult] with score + human-readable label.
  /// On error, returns a neutral result (score: 0.5) rather than crashing.
  Future<B2bCompatibilityResult> getCompatibilityScore({
    required String categoryA,
    required String categoryB,
    required double distanceKm,
  }) async {
    try {
      debugPrint(
          'B2bService: Predicting compatibility for $categoryA ↔ $categoryB (${distanceKm}km)...');

      final response = await _httpClient
          .post(
            Uri.parse(AiEndpoints.b2bMatch),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseAnonKey',
              'apikey': _supabaseAnonKey,
            },
            body: jsonEncode({
              'category_a': categoryA,
              'category_b': categoryB,
              'distance_km': distanceKm,
            }),
          )
          .timeout(AiEndpoints.coldStartTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = B2bCompatibilityResult.fromJson(data);
        debugPrint('B2bService: Score = ${result.compatibilityScore}');
        return result;
      } else {
        debugPrint(
            'B2bService Error: HTTP ${response.statusCode} — ${response.body}');
        return const B2bCompatibilityResult(compatibilityScore: 0.5);
      }
    } catch (e) {
      debugPrint('B2bService Exception: $e');
      return const B2bCompatibilityResult(compatibilityScore: 0.5);
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
