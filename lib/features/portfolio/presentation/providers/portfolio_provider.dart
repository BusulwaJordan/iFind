import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/portfolio/data/repositories/portfolio_repository.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/media/services/media_service_provider.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final mediaService = ref.watch(mediaServiceProvider);
  return PortfolioRepository(Supabase.instance.client, mediaService);
});

final portfolioProvider = FutureProvider.family<List<PortfolioItem>, String>((ref, businessId) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  final result = await repository.getPortfolio(businessId);
  return result.fold(
    (failure) => [],
    (items) => items,
  );
});
