import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/notifications/data/models/notification_model.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _client;

  NotificationRepositoryImpl(this._client);

  @override
  Stream<List<AppNotification>> watchNotifications(String businessId) async* {
    while (true) {
      yield await _fetchBusinessNotifications(businessId);
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  Future<List<AppNotification>> _fetchBusinessNotifications(
      String businessId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) async* {
    while (true) {
      yield await _fetchUserNotifications(userId);
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  Future<List<AppNotification>> _fetchUserNotifications(String userId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
      String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createNotification({
    String? userId,
    String? businessId,
    String? needId,
    String? type,
    Map<String, dynamic>? data,
    required String title,
    required String body,
  }) async {
    try {
      await _client.from('notifications').insert({
        if (userId != null) 'user_id': userId,
        if (businessId != null) 'business_id': businessId,
        if (needId != null) 'need_id': needId,
        if (type != null) 'type': type,
        if (data != null) 'data': data,
        'title': title,
        'body': body,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
