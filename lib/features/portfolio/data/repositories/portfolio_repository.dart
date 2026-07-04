import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/media/services/media_service.dart';

class PortfolioRepository {
  final SupabaseClient _client;
  final MediaService _mediaService;

  PortfolioRepository(this._client, this._mediaService);

  /// `portfolio_items.business_id` is the UUID primary key on `businesses`,
  /// but callers pass the custom text business id (e.g. "BIZ0122") used
  /// everywhere else in the app. Resolve the UUID before querying/writing.
  Future<String?> _resolveBusinessUuid(String businessId) async {
    final row = await _client
        .from('businesses')
        .select('id')
        .eq('business_id', businessId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<Either<Failure, List<PortfolioItem>>> getPortfolio(String businessId) async {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId) ?? businessId;
      final response = await _client
          .from('portfolio_items')
          .select()
          .eq('business_id', resolvedId)
          .order('created_at', ascending: false);

      final items = (response as List).map((json) => PortfolioItem.fromJson(json)).toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, PortfolioItem>> uploadPortfolioItem({
    required String businessId,
    required XFile file,
    required MediaType type,
    String? caption,
    double? price,
  }) async {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId);
      if (resolvedId == null) {
        return const Left(ServerFailure('Business not found'));
      }

      // 1. Upload media (bytes-based — works on web and native)
      final fileExt = type == MediaType.video ? 'mp4' : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final bucket = type == MediaType.video ? 'business_videos' : 'business_portfolios';
      final path = '$businessId/$fileName';
      final bytes = await file.readAsBytes();

      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: file.mimeType),
          );
      final mediaUrl = _client.storage.from(bucket).getPublicUrl(path);

      // 2. Generate and Upload Thumbnail (video, native only — MediaService
      // relies on dart:io/path_provider which don't work on web)
      String? thumbnailUrl;
      if (type == MediaType.video && !kIsWeb) {
        try {
          final thumbnailFile = await _mediaService.generateThumbnail(File(file.path));
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
        'business_id': resolvedId,
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

  /// Adds an existing, already-uploaded media URL as a portfolio item
  /// without re-uploading it — used to surface a product's cover photo in
  /// the gallery when the product is created.
  Future<Either<Failure, PortfolioItem>> addMediaUrlAsPortfolioItem({
    required String businessId,
    required String mediaUrl,
    required MediaType mediaType,
    String? caption,
    double? price,
    String? productId,
  }) async {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId);
      if (resolvedId == null) {
        return const Left(ServerFailure('Business not found'));
      }

      final itemData = {
        'business_id': resolvedId,
        'media_type': mediaType.name,
        'media_url': mediaUrl,
        'thumbnail_url': null,
        'caption': caption,
        'price': price,
        'product_id': productId,
      };

      final response = await _client.from('portfolio_items').insert(itemData).select().single();
      return Right(PortfolioItem.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Keeps a product's linked gallery post in sync when the product is
  /// edited — updates the existing post if one exists, creates one if the
  /// product didn't have images before but does now, and removes it if the
  /// product no longer has any images.
  Future<void> syncProductPortfolioItem({
    required String businessId,
    required String productId,
    required String? coverImageUrl,
    required String caption,
    required double price,
  }) async {
    final existing = await _client
        .from('portfolio_items')
        .select('id')
        .eq('product_id', productId)
        .maybeSingle();

    if (coverImageUrl == null) {
      if (existing != null) {
        await _client.from('portfolio_items').delete().eq('id', existing['id']);
      }
      return;
    }

    if (existing != null) {
      await _client.from('portfolio_items').update({
        'media_url': coverImageUrl,
        'caption': caption,
        'price': price,
      }).eq('id', existing['id']);
    } else {
      final resolvedId = await _resolveBusinessUuid(businessId);
      if (resolvedId == null) return;
      await _client.from('portfolio_items').insert({
        'business_id': resolvedId,
        'media_type': MediaType.image.name,
        'media_url': coverImageUrl,
        'caption': caption,
        'price': price,
        'product_id': productId,
      });
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
