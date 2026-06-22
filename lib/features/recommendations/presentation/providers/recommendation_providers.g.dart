// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiRecommendationDataSourceHash() =>
    r'29dc25a3434f4ff0ef1ed8fff28dc3952ca3d6c3';

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
String _$userRecommendationsHash() =>
    r'302b8c0713ca0557236299abcd7b52858382382b';

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

/// Fetches personalized B2C recommendations for [userId].
///
/// New users (no interactions yet) will get an empty list — the UI should
/// fall back to featured or popular businesses in that case.
///
/// Copied from [userRecommendations].
@ProviderFor(userRecommendations)
const userRecommendationsProvider = UserRecommendationsFamily();

/// Fetches personalized B2C recommendations for [userId].
///
/// New users (no interactions yet) will get an empty list — the UI should
/// fall back to featured or popular businesses in that case.
///
/// Copied from [userRecommendations].
class UserRecommendationsFamily
    extends Family<AsyncValue<List<Recommendation>>> {
  /// Fetches personalized B2C recommendations for [userId].
  ///
  /// New users (no interactions yet) will get an empty list — the UI should
  /// fall back to featured or popular businesses in that case.
  ///
  /// Copied from [userRecommendations].
  const UserRecommendationsFamily();

  /// Fetches personalized B2C recommendations for [userId].
  ///
  /// New users (no interactions yet) will get an empty list — the UI should
  /// fall back to featured or popular businesses in that case.
  ///
  /// Copied from [userRecommendations].
  UserRecommendationsProvider call({
    required String userId,
    int n = 5,
  }) {
    return UserRecommendationsProvider(
      userId: userId,
      n: n,
    );
  }

  @override
  UserRecommendationsProvider getProviderOverride(
    covariant UserRecommendationsProvider provider,
  ) {
    return call(
      userId: provider.userId,
      n: provider.n,
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
  String? get name => r'userRecommendationsProvider';
}

/// Fetches personalized B2C recommendations for [userId].
///
/// New users (no interactions yet) will get an empty list — the UI should
/// fall back to featured or popular businesses in that case.
///
/// Copied from [userRecommendations].
class UserRecommendationsProvider
    extends AutoDisposeFutureProvider<List<Recommendation>> {
  /// Fetches personalized B2C recommendations for [userId].
  ///
  /// New users (no interactions yet) will get an empty list — the UI should
  /// fall back to featured or popular businesses in that case.
  ///
  /// Copied from [userRecommendations].
  UserRecommendationsProvider({
    required String userId,
    int n = 5,
  }) : this._internal(
          (ref) => userRecommendations(
            ref as UserRecommendationsRef,
            userId: userId,
            n: n,
          ),
          from: userRecommendationsProvider,
          name: r'userRecommendationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userRecommendationsHash,
          dependencies: UserRecommendationsFamily._dependencies,
          allTransitiveDependencies:
              UserRecommendationsFamily._allTransitiveDependencies,
          userId: userId,
          n: n,
        );

  UserRecommendationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.n,
  }) : super.internal();

  final String userId;
  final int n;

  @override
  Override overrideWith(
    FutureOr<List<Recommendation>> Function(UserRecommendationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserRecommendationsProvider._internal(
        (ref) => create(ref as UserRecommendationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        n: n,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Recommendation>> createElement() {
    return _UserRecommendationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserRecommendationsProvider &&
        other.userId == userId &&
        other.n == n;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, n.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserRecommendationsRef
    on AutoDisposeFutureProviderRef<List<Recommendation>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `n` of this provider.
  int get n;
}

class _UserRecommendationsProviderElement
    extends AutoDisposeFutureProviderElement<List<Recommendation>>
    with UserRecommendationsRef {
  _UserRecommendationsProviderElement(super.provider);

  @override
  String get userId => (origin as UserRecommendationsProvider).userId;
  @override
  int get n => (origin as UserRecommendationsProvider).n;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
