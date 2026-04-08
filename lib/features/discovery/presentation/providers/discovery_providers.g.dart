// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoveryRemoteDataSourceHash() =>
    r'641b9710c4f8226d598edc9fa8f4c5a2b3de1323';

/// See also [discoveryRemoteDataSource].
@ProviderFor(discoveryRemoteDataSource)
final discoveryRemoteDataSourceProvider =
    AutoDisposeProvider<DiscoveryRemoteDataSource>.internal(
  discoveryRemoteDataSource,
  name: r'discoveryRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$discoveryRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveryRemoteDataSourceRef
    = AutoDisposeProviderRef<DiscoveryRemoteDataSource>;
String _$discoveryRepositoryHash() =>
    r'cff42187dc8b1bc12cd1b0f5fbb8bf917879b802';

/// See also [discoveryRepository].
@ProviderFor(discoveryRepository)
final discoveryRepositoryProvider =
    AutoDisposeProvider<DiscoveryRepository>.internal(
  discoveryRepository,
  name: r'discoveryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$discoveryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveryRepositoryRef = AutoDisposeProviderRef<DiscoveryRepository>;
String _$nearbyBusinessesHash() => r'89a1ec9148bcd0f93f4967564e1033e16cf43c27';

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

/// See also [nearbyBusinesses].
@ProviderFor(nearbyBusinesses)
const nearbyBusinessesProvider = NearbyBusinessesFamily();

/// See also [nearbyBusinesses].
class NearbyBusinessesFamily extends Family<AsyncValue<List<Business>>> {
  /// See also [nearbyBusinesses].
  const NearbyBusinessesFamily();

  /// See also [nearbyBusinesses].
  NearbyBusinessesProvider call({
    required double latitude,
    required double longitude,
    double radius = 5000.0,
  }) {
    return NearbyBusinessesProvider(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  @override
  NearbyBusinessesProvider getProviderOverride(
    covariant NearbyBusinessesProvider provider,
  ) {
    return call(
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
  String? get name => r'nearbyBusinessesProvider';
}

/// See also [nearbyBusinesses].
class NearbyBusinessesProvider
    extends AutoDisposeFutureProvider<List<Business>> {
  /// See also [nearbyBusinesses].
  NearbyBusinessesProvider({
    required double latitude,
    required double longitude,
    double radius = 5000.0,
  }) : this._internal(
          (ref) => nearbyBusinesses(
            ref as NearbyBusinessesRef,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          ),
          from: nearbyBusinessesProvider,
          name: r'nearbyBusinessesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nearbyBusinessesHash,
          dependencies: NearbyBusinessesFamily._dependencies,
          allTransitiveDependencies:
              NearbyBusinessesFamily._allTransitiveDependencies,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

  NearbyBusinessesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.latitude,
    required this.longitude,
    required this.radius,
  }) : super.internal();

  final double latitude;
  final double longitude;
  final double radius;

  @override
  Override overrideWith(
    FutureOr<List<Business>> Function(NearbyBusinessesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NearbyBusinessesProvider._internal(
        (ref) => create(ref as NearbyBusinessesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Business>> createElement() {
    return _NearbyBusinessesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyBusinessesProvider &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, latitude.hashCode);
    hash = _SystemHash.combine(hash, longitude.hashCode);
    hash = _SystemHash.combine(hash, radius.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NearbyBusinessesRef on AutoDisposeFutureProviderRef<List<Business>> {
  /// The parameter `latitude` of this provider.
  double get latitude;

  /// The parameter `longitude` of this provider.
  double get longitude;

  /// The parameter `radius` of this provider.
  double get radius;
}

class _NearbyBusinessesProviderElement
    extends AutoDisposeFutureProviderElement<List<Business>>
    with NearbyBusinessesRef {
  _NearbyBusinessesProviderElement(super.provider);

  @override
  double get latitude => (origin as NearbyBusinessesProvider).latitude;
  @override
  double get longitude => (origin as NearbyBusinessesProvider).longitude;
  @override
  double get radius => (origin as NearbyBusinessesProvider).radius;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
