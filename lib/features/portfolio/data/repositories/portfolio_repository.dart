import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/media/services/media_service.dart';

class PortfolioRepository {
  final SupabaseClient _client;
  final MediaService _mediaService;

  PortfolioRepository(this._client, this._mediaService);

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
    double? price,
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
      if (type == MediaType.video) {
        try {
          final thumbnailFile = await _mediaService.generateThumbnail(file);
          if (thumbnailFile != null) {
            final thumbFileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final thumbPath = '$businessId/$thumbFileName';
            
            await _client.storage.from('business_portfolios').upload(thumbPath, thumbnailFile);
            thumbnailUrl = _client.storage.from('business_portfolios').getPublicUrl(thumbPath);
          }
        } catch (_) {
          // Fallback handled by null check
        }
      }

      // 3. Insert Record
      final itemData = {
        'business_id': businessId,
        'media_type': type.name,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
        'price': price,
      };

      final response = await _client.from('portfolio_items').insert(itemData).select().single();
      return Right(PortfolioItem.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deletePortfolioItem(String itemId) async {
    try {
      // 1. Fetch item to get URLs for cleanup
      final response = await _client.from('portfolio_items').select().eq('id', itemId).maybeSingle();
      if (response != null) {
        final item = PortfolioItem.fromJson(response);
        
        // 2. Cleanup Storage
        final uri = Uri.parse(item.mediaUrl);
        final pathParts = uri.path.split('public/')[1].split('/');
        final bucket = pathParts[0];
        final path = pathParts.sublist(1).join('/');
        await _client.storage.from(bucket).remove([path]);
        
        if (item.thumbnailUrl != null) {
          final tUri = Uri.parse(item.thumbnailUrl!);
          final tPathParts = tUri.path.split('public/')[1].split('/');
          final tBucket = tPathParts[0];
          final tPath = tPathParts.sublist(1).join('/');
          await _client.storage.from(tBucket).remove([tPath]);
        }
      }

      // 3. Delete Record
      await _client.from('portfolio_items').delete().eq('id', itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
