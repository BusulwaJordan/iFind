import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:ifind/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:ifind/features/discovery/domain/repositories/discovery_repository.dart';

part 'discovery_providers.g.dart';

@riverpod
DiscoveryRemoteDataSource discoveryRemoteDataSource(Ref ref) {
  return DiscoveryRemoteDataSourceImpl(Supabase.instance.client);
}

@riverpod
DiscoveryRepository discoveryRepository(Ref ref) {
  final remoteDataSource = ref.watch(discoveryRemoteDataSourceProvider);
  return DiscoveryRepositoryImpl(remoteDataSource);
}

@riverpod
Future<List<Business>> nearbyBusinesses(
  Ref ref, {
  required double latitude,
  required double longitude,
  double radius = 5000.0,
}) async {
  final repository = ref.watch(discoveryRepositoryProvider);
  final result = await repository.getNearbyBusinesses(
    latitude: latitude,
    longitude: longitude,
    radiusInMeters: radius,
  );
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (businesses) => businesses,
  );
}
