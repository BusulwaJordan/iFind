// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiRecommendationDataSourceHash() =>
    r'e12409780a1fb026c1ec0cfb1b4343015917722c';

/// See also [aiRecommendationDataSource].
@ProviderFor(aiRecommendationDataSource)
final aiRecommendationDataSourceProvider =
    AutoDisposeProvider<AiRecommendationDataSource>.internal(
  aiRecommendationDataSource,
  name: r'aiRecommendationDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiRecommendationDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiRecommendationDataSourceRef
    = AutoDisposeProviderRef<AiRecommendationDataSource>;
String _$recommendationRepositoryHash() =>
    r'eb15b31546651021bb356a3fe1766c7f1acbfcfd';

/// See also [recommendationRepository].
@ProviderFor(recommendationRepository)
final recommendationRepositoryProvider =
    AutoDisposeProvider<RecommendationRepository>.internal(
  recommendationRepository,
  name: r'recommendationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recommendationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendationRepositoryRef
    = AutoDisposeProviderRef<RecommendationRepository>;
String _$aiMatchmakingHash() => r'ec6df9c8345db58dc1166134de315660299704aa';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [aiMatchmaking].
@ProviderFor(aiMatchmaking)
const aiMatchmakingProvider = AiMatchmakingFamily();

/// See also [aiMatchmaking].
class AiMatchmakingFamily extends Family<AsyncValue<List<Recommendation>>> {
  /// See also [aiMatchmaking].
  const AiMatchmakingFamily();

  /// See also [aiMatchmaking].
  AiMatchmakingProvider call({
    required String intent,
    required double latitude,
    required double longitude,
    double radius = 5000.0,
  }) {
    return AiMatchmakingProvider(
      intent: intent,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  @override
  AiMatchmakingProvider getProviderOverride(
    covariant AiMatchmakingProvider provider,
  ) {
    return call(
      intent: provider.intent,
      latitude: provider.latitude,
      longitude: provider.longitude,
      radius: provider.radius,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'aiMatchmakingProvider';
}

/// See also [aiMatchmaking].
class AiMatchmakingProvider
    extends AutoDisposeFutureProvider<List<Recommendation>> {
  /// See also [aiMatchmaking].
  AiMatchmakingProvider({
    required String intent,
    required double latitude,
    required double longitude,
    double radius = 5000.0,
  }) : this._internal(
          (ref) => aiMatchmaking(
            ref as AiMatchmakingRef,
            intent: intent,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          ),
          from: aiMatchmakingProvider,
          name: r'aiMatchmakingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$aiMatchmakingHash,
          dependencies: AiMatchmakingFamily._dependencies,
          allTransitiveDependencies:
              AiMatchmakingFamily._allTransitiveDependencies,
          intent: intent,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

  AiMatchmakingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.intent,
    required this.latitude,
    required this.longitude,
    required this.radius,
  }) : super.internal();

  final String intent;
  final double latitude;
  final double longitude;
  final double radius;

  @override
  Override overrideWith(
    FutureOr<List<Recommendation>> Function(AiMatchmakingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AiMatchmakingProvider._internal(
        (ref) => create(ref as AiMatchmakingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        intent: intent,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Recommendation>> createElement() {
    return _AiMatchmakingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiMatchmakingProvider &&
        other.intent == intent &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, intent.hashCode);
    hash = _SystemHash.combine(hash, latitude.hashCode);
    hash = _SystemHash.combine(hash, longitude.hashCode);
    hash = _SystemHash.combine(hash, radius.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AiMatchmakingRef on AutoDisposeFutureProviderRef<List<Recommendation>> {
  /// The parameter `intent` of this provider.
  String get intent;

  /// The parameter `latitude` of this provider.
  double get latitude;

  /// The parameter `longitude` of this provider.
  double get longitude;

  /// The parameter `radius` of this provider.
  double get radius;
}

class _AiMatchmakingProviderElement
    extends AutoDisposeFutureProviderElement<List<Recommendation>>
    with AiMatchmakingRef {
  _AiMatchmakingProviderElement(super.provider);

  @override
  String get intent => (origin as AiMatchmakingProvider).intent;
  @override
  double get latitude => (origin as AiMatchmakingProvider).latitude;
  @override
  double get longitude => (origin as AiMatchmakingProvider).longitude;
  @override
  double get radius => (origin as AiMatchmakingProvider).radius;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
