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
  Stream<List<AppNotification>> watchNotifications(String businessId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('created_at') // Newest last (append to bottom) or reverse in UI
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList().reversed.toList());
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
