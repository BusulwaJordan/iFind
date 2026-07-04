import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/needs/data/repositories/needs_repository.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';

final needsRepositoryProvider = Provider<NeedsRepository>((ref) {
  return NeedsRepository(Supabase.instance.client);
});

BusinessCategory businessCategoryForNeedCategory(String category) {
  final normalized = category.toLowerCase();

  if (normalized.contains('food') ||
      normalized.contains('drink') ||
      normalized.contains('bakery') ||
      normalized.contains('cake')) {
    return BusinessCategory.food;
  }
  if (normalized.contains('beauty') ||
      normalized.contains('salon') ||
      normalized.contains('makeup') ||
      normalized.contains('hair')) {
    return BusinessCategory.beauty;
  }
  if (normalized.contains('fashion') ||
      normalized.contains('clothes') ||
      normalized.contains('wear')) {
    return BusinessCategory.fashion;
  }
  if (normalized.contains('electronic') ||
      normalized.contains('phone') ||
      normalized.contains('computer')) {
    return BusinessCategory.electronics;
  }
  if (normalized.contains('home') ||
      normalized.contains('plumb') ||
      normalized.contains('repair') ||
      normalized.contains('service')) {
    return BusinessCategory.service;
  }
  if (normalized.contains('retail') || normalized.contains('shop')) {
    return BusinessCategory.retail;
  }
  if (normalized.contains('health') || normalized.contains('medical')) {
    return BusinessCategory.health;
  }
  if (normalized.contains('education') || normalized.contains('school')) {
    return BusinessCategory.education;
  }
  if (normalized.contains('entertainment') || normalized.contains('event')) {
    return BusinessCategory.entertainment;
  }

  return BusinessCategory.other;
}

class NeedAnalysis {
  final String category;
  final BusinessCategory businessCategory;
  final String urgency;
  final List<String> keywords;
  final double confidence;

  const NeedAnalysis({
    required this.category,
    required this.businessCategory,
    required this.urgency,
    required this.keywords,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'businessCategory': businessCategory.name,
        'urgency': urgency,
        'tags': keywords,
        'confidence': confidence,
      };
}

class _CategoryRule {
  final BusinessCategory category;
  final String label;
  final Map<String, double> keywords;

  const _CategoryRule({
    required this.category,
    required this.label,
    required this.keywords,
  });
}

const _categoryRules = [
  _CategoryRule(
    category: BusinessCategory.food,
    label: 'Food & Drink',
    keywords: {
      'food': 2,
      'cake': 4,
      'bakery': 4,
      'bread': 3,
      'restaurant': 3,
      'catering': 4,
      'lunch': 2,
      'dinner': 2,
      'drink': 2,
      'juice': 2,
      'birthday': 1,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.beauty,
    label: 'Beauty',
    keywords: {
      'beauty': 3,
      'salon': 4,
      'hair': 4,
      'makeup': 4,
      'nails': 3,
      'spa': 3,
      'facial': 3,
      'braids': 4,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.electronics,
    label: 'Electronics',
    keywords: {
      'phone': 4,
      'laptop': 4,
      'computer': 4,
      'charger': 3,
      'electronics': 3,
      'repair phone': 5,
      'screen': 2,
      'tv': 3,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.service,
    label: 'Home Services',
    keywords: {
      'plumber': 5,
      'plumbing': 5,
      'electrician': 5,
      'repair': 3,
      'fix': 3,
      'cleaning': 4,
      'service': 2,
      'install': 3,
      'maintenance': 3,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.fashion,
    label: 'Fashion',
    keywords: {
      'fashion': 3,
      'clothes': 4,
      'dress': 4,
      'shoes': 3,
      'wear': 3,
      'tailor': 4,
      'suit': 3,
      'bags': 2,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.health,
    label: 'Health',
    keywords: {
      'doctor': 4,
      'clinic': 4,
      'medicine': 4,
      'medical': 4,
      'health': 3,
      'pharmacy': 4,
      'dentist': 4,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.education,
    label: 'Education',
    keywords: {
      'school': 4,
      'teacher': 4,
      'tutor': 4,
      'lesson': 3,
      'education': 3,
      'training': 3,
      'course': 3,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.entertainment,
    label: 'Entertainment',
    keywords: {
      'event': 4,
      'music': 3,
      'dj': 4,
      'party': 3,
      'photographer': 4,
      'video': 3,
      'entertainment': 3,
    },
  ),
  _CategoryRule(
    category: BusinessCategory.retail,
    label: 'Retail',
    keywords: {
      'shop': 2,
      'buy': 2,
      'store': 2,
      'supplier': 3,
      'wholesale': 3,
      'retail': 3,
      'market': 2,
    },
  ),
];

final myNeedsProvider =
    StreamProvider.family<List<Need>, String>((ref, userId) {
  return ref.watch(needsRepositoryProvider).watchMyNeeds(userId);
});

final businessLeadsProvider =
    FutureProvider.family<List<Need>, Business>((ref, business) async {
  final repository = ref.read(needsRepositoryProvider);
  final supabase = Supabase.instance.client;

  final needs = await repository.getNearbyNeeds(
    business.latitude,
    business.longitude,
    20.0,
  );

  // Exclude customers already contacted by this business
  final chatsResp = await supabase
      .from('chats')
      .select('customer_id')
      .eq('business_id', business.id)
      .eq('is_b2b', false);
  final contactedIds = (chatsResp as List)
      .map((c) => c['customer_id'] as String?)
      .whereType<String>()
      .toSet();

  return needs
      .where((need) =>
          businessCategoryForNeedCategory(need.category) == business.category &&
          need.userId != business.ownerId &&
          !contactedIds.contains(need.userId))
      .toList();
});

/*
  Controller for posting a need.
  Handles AI analysis and submission.
*/
class PostNeedState {
  final bool isAnalyzing;
  final bool isSubmitting;
  final Map<String, dynamic>? aiAnalysis;
  final List<Business> matchingBusinesses;
  final String? error;

  PostNeedState({
    this.isAnalyzing = false,
    this.isSubmitting = false,
    this.aiAnalysis,
    this.matchingBusinesses = const [],
    this.error,
  });

  PostNeedState copyWith({
    bool? isAnalyzing,
    bool? isSubmitting,
    Map<String, dynamic>? aiAnalysis,
    List<Business>? matchingBusinesses,
    String? error,
  }) {
    return PostNeedState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      matchingBusinesses: matchingBusinesses ?? this.matchingBusinesses,
      error: error, // Clear error if not provided (or manage explicitly)
    );
  }
}

class PostNeedController extends StateNotifier<PostNeedState> {
  final NeedsRepository _needsRepository;
  final BusinessRepository _businessRepository;
  final NotificationRepository _notificationRepository;

  PostNeedController(
    this._needsRepository,
    this._businessRepository,
    this._notificationRepository,
  ) : super(PostNeedState());

  Future<void> analyzeText(String text) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final analysis = _analyzeNeed(text);
      final result = analysis.toJson();
      final position = await _getCurrentPosition();

      final businessesResult = await _businessRepository.getNearbyBusinesses(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusForUrgency(analysis.urgency),
        category: analysis.businessCategory == BusinessCategory.other
            ? null
            : analysis.businessCategory,
      );

      final businesses = _rankBusinesses(
        businessesResult.getOrElse(() => []),
        analysis,
      );

      state = state.copyWith(
        isAnalyzing: false,
        aiAnalysis: result,
        matchingBusinesses: businesses,
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  Future<({double latitude, double longitude})> _getCurrentPosition() async {
    const fallback = (latitude: 0.3476, longitude: 32.5825);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        return (latitude: position.latitude, longitude: position.longitude);
      }
    } catch (_) {}

    return fallback;
  }

  NeedAnalysis _analyzeNeed(String text) {
    final normalized = text.toLowerCase();
    final categoryScores = <_CategoryRule, double>{};
    final matchedKeywords = <String>{};

    for (final rule in _categoryRules) {
      var score = 0.0;
      for (final entry in rule.keywords.entries) {
        if (normalized.contains(entry.key)) {
          score += entry.value;
          matchedKeywords.add(_titleCase(entry.key));
        }
      }
      if (score > 0) categoryScores[rule] = score;
    }

    final bestEntry = categoryScores.entries.isEmpty
        ? null
        : (categoryScores.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    final urgency = _detectUrgency(normalized);

    if (bestEntry == null) {
      return NeedAnalysis(
        category: 'General',
        businessCategory: BusinessCategory.other,
        urgency: urgency,
        keywords: const ['General'],
        confidence: 0,
      );
    }

    final totalScore =
        categoryScores.values.fold<double>(0, (sum, score) => sum + score);
    final confidence = totalScore == 0 ? 0.0 : bestEntry.value / totalScore;

    return NeedAnalysis(
      category: bestEntry.key.label,
      businessCategory: bestEntry.key.category,
      urgency: urgency,
      keywords: matchedKeywords.take(6).toList(),
      confidence: confidence,
    );
  }

  BusinessCategory _stringToBusinessCategory(String category) {
    return businessCategoryForNeedCategory(category);
  }

  String _detectUrgency(String normalizedText) {
    const urgentWords = [
      'urgent',
      'now',
      'today',
      'asap',
      'emergency',
      'immediately',
      'right away',
    ];
    const soonWords = ['tomorrow', 'soon', 'this week', 'quick', 'fast'];

    if (urgentWords.any(normalizedText.contains)) return 'High';
    if (soonWords.any(normalizedText.contains)) return 'Medium';
    return 'Low';
  }

  double _radiusForUrgency(String urgency) {
    switch (urgency) {
      case 'High':
        return 10;
      case 'Medium':
        return 15;
      default:
        return 20;
    }
  }

  List<Business> _rankBusinesses(
    List<Business> businesses,
    NeedAnalysis analysis,
  ) {
    final ranked = [...businesses]..sort((a, b) {
        final aScore = _businessMatchScore(a, analysis);
        final bScore = _businessMatchScore(b, analysis);
        return bScore.compareTo(aScore);
      });

    return ranked;
  }

  double _businessMatchScore(Business business, NeedAnalysis analysis) {
    final distance = business.distance ?? 20;
    final distanceScore = (1 - (distance / 20)).clamp(0.0, 1.0) * 45;
    final ratingScore = (business.rating / 5).clamp(0.0, 1.0) * 25;
    final reviewScore = (business.reviewCount / 30).clamp(0.0, 1.0) * 15;
    final verifiedScore = business.isVerified ? 10.0 : 0.0;
    final categoryScore =
        business.category == analysis.businessCategory ? 25.0 : 0.0;

    return distanceScore +
        ratingScore +
        reviewScore +
        verifiedScore +
        categoryScore;
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Future<bool> submitNeed({
    required String userId,
    required String title,
    required String description,
    required String category,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final position = await _getCurrentPosition();
      final need = Need(
        id: '', // DB will generate
        userId: userId,
        title: title,
        description: description,
        category: category,
        latitude: position.latitude,
        longitude: position.longitude,
        status: NeedStatus.active,
        createdAt: DateTime.now(),
      );

      final needId = await _needsRepository.createNeed(need);

      final analysis = state.aiAnalysis == null
          ? _analyzeNeed('$title $description')
          : NeedAnalysis(
              category: state.aiAnalysis!['category'] as String? ?? category,
              businessCategory: _stringToBusinessCategory(
                state.aiAnalysis!['category'] as String? ?? category,
              ),
              urgency: state.aiAnalysis!['urgency'] as String? ?? 'Low',
              keywords: (state.aiAnalysis!['tags'] as List?)?.cast<String>() ??
                  const [],
              confidence:
                  (state.aiAnalysis!['confidence'] as num?)?.toDouble() ?? 0,
            );
      final targetCategory = analysis.businessCategory;
      final relevantBusinesses = state.matchingBusinesses
          .where((business) =>
              targetCategory != BusinessCategory.other &&
              business.category == targetCategory)
          .toList()
        ..sort((a, b) => _businessMatchScore(b, analysis)
            .compareTo(_businessMatchScore(a, analysis)));

      // Notify only the strongest businesses for this need.
      for (final business in relevantBusinesses.take(8)) {
        await _notificationRepository.createNotification(
          businessId: business.id,
          needId: needId,
          type: 'need_match',
          data: {
            'need_id': needId,
            'business_id': business.id,
            'customer_id': userId,
            'category': category,
            'urgency': analysis.urgency,
            'keywords': analysis.keywords,
            'match_score': _businessMatchScore(business, analysis),
            'distance_km': business.distance,
          },
          title: 'New Match: $title',
          body: '${analysis.urgency} urgency ${analysis.category} need nearby. '
              'Tap to view and message the customer.',
        );
      }

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final postNeedProvider =
    StateNotifierProvider<PostNeedController, PostNeedState>((ref) {
  return PostNeedController(
    ref.watch(needsRepositoryProvider),
    ref.watch(businessRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
});

/// Businesses that match the user's active posted needs.
/// Returns a list of (need, businesses) pairs so the UI can show context.
final needsBasedBusinessesProvider = FutureProvider.family<
    List<({Need need, List<Business> businesses})>, String>(
  (ref, userId) async {
    final needsRepo = ref.read(needsRepositoryProvider);
    final businessRepo = ref.read(businessRepositoryProvider);

    final needs = await needsRepo.getMyNeeds(userId);
    if (needs.isEmpty) return [];

    // Get current position, fall back to Kampala centre
    double lat = 0.3476, lng = 32.5825;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    final result = <({Need need, List<Business> businesses})>[];
    final seenIds = <String>{};

    for (final need in needs) {
      final category = businessCategoryForNeedCategory(need.category);
      final businessesResult = await businessRepo.getNearbyBusinesses(
        latitude: lat,
        longitude: lng,
        radiusKm: 20.0,
        category: category == BusinessCategory.other ? null : category,
      );
      final businesses = businessesResult
          .getOrElse(() => [])
          .where((b) => seenIds.add(b.id))
          .take(6)
          .toList();
      if (businesses.isNotEmpty) {
        result.add((need: need, businesses: businesses));
      }
    }
    return result;
  },
);

final nearbyNeedsProvider = FutureProvider<List<Need>>((ref) async {
  final repository = ref.read(needsRepositoryProvider);
  // Hardcoded location for MVP, or use Geolocator
  return repository.getNearbyNeeds(0.3476, 32.5825, 10.0);
});
