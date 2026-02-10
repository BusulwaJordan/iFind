import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';

class PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepository(this._client);

  Future<Either<Failure, List<PortfolioItem>>> getPortfolio(String businessId) async {
    try {
      final response = await _client
          .from('portfolio_items')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
          
      final items = (response as List).map((json) => PortfolioItem.fromJson(json)).toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, PortfolioItem>> uploadPortfolioItem({
    required String businessId,
    required File file,
    required MediaType type,
    String? caption,
  }) async {
    try {
      // 1. Upload File
      final fileExt = type == MediaType.video ? 'mp4' : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final bucket = type == MediaType.video ? 'business_videos' : 'business_portfolios';
      final path = '$businessId/$fileName';

      await _client.storage.from(bucket).upload(path, file);
      final mediaUrl = _client.storage.from(bucket).getPublicUrl(path);

      // 2. Generate and Upload Thumbnail (if video)
      String? thumbnailUrl;
      /* 
      if (type == MediaType.video) {
        // Assume thumbnail generated and passed in, or ignore for now to keep simple
      }
      */

      // 3. Insert Record
      final itemData = {
        'business_id': businessId,
        'media_type': type.name,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
      };

      final response = await _client.from('portfolio_items').insert(itemData).select().single();
      return Right(PortfolioItem.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deletePortfolioItem(String itemId) async {
    try {
      await _client.from('portfolio_items').delete().eq('id', itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
