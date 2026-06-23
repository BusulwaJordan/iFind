import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ifind/core/constants/ai_endpoints.dart';

/// A single recommended business returned by the B2C model.
class BusinessRecommendation {
  final String businessId;
  final String name;
  final String category;
  final double score;

  const BusinessRecommendation({
    required this.businessId,
    required this.name,
    required this.category,
    required this.score,
  });

  factory BusinessRecommendation.fromJson(Map<String, dynamic> json) {
    return BusinessRecommendation(
      businessId: (json['business_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Business').toString(),
      category: (json['category'] ?? 'general').toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'BusinessRecommendation(id: $businessId, name: $name, score: $score)';
}

/// MODEL 2: B2C Collaborative Filtering Recommender
///
/// Calls the `recommend-businesses` Supabase Edge Function, which loads
/// a pre-trained ALS (Alternating Least Squares) model from Supabase Storage.
///
/// The model was trained on [interactions_clean.csv] containing:
/// view, search_click, profile_view, saved_business, inquiry_sent, review_posted
///
/// Cold start (first request): 3–5 seconds (model downloads from Storage)
/// Warm requests: < 500ms (model cached in Edge Function memory)
class RecommendationService {
  final http.Client _httpClient;
  final String _supabaseAnonKey;

  RecommendationService({
    http.Client? httpClient,
    required String supabaseAnonKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _supabaseAnonKey = supabaseAnonKey;

  /// Returns top [n] business recommendations for [userId].
  ///
  /// If the user has no interactions in the model (cold-start new user),
  /// returns an empty list — the caller should fall back to popular businesses.
  ///
  /// On any network or model error, logs and returns an empty list.
  Future<List<BusinessRecommendation>> getRecommendations({
    required String userId,
    int n = 5,
  }) async {
    try {
      debugPrint('RecommendationService: Fetching recs for user $userId...');

      final response = await _httpClient
          .post(
            Uri.parse(AiEndpoints.recommendBusinesses),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseAnonKey',
              'apikey': _supabaseAnonKey,
            },
            body: jsonEncode({'user_id': userId, 'n': n}),
          )
          .timeout(AiEndpoints.coldStartTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Edge Function may return {"recommendations": [...]} or just [...]
        List<dynamic> rawList;
        if (data is List) {
          rawList = data;
        } else if (data is Map && data.containsKey('recommendations')) {
          rawList = data['recommendations'] as List;
        } else {
          rawList = [];
        }

        final recs = rawList
            .map((e) => BusinessRecommendation.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();

        debugPrint(
            'RecommendationService: Got ${recs.length} recommendations.');
        return recs;
      } else if (response.statusCode == 404) {
        // User not found in model — cold-start new user
        debugPrint(
            'RecommendationService: User $userId not in model (new user).');
        return [];
      } else {
        debugPrint(
            'RecommendationService Error: HTTP ${response.statusCode} — ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('RecommendationService Exception: $e');
      return [];
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
