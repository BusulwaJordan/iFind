import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// Stream notifications for a specific business
  Stream<List<AppNotification>> watchNotifications(String businessId);

  /// Stream notifications for a specific user
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Create a new notification
  Future<Either<Failure, void>> createNotification({
    String? userId,
    String? businessId,
    String? needId,
    String? type,
    Map<String, dynamic>? data,
    required String title,
    required String body,
  });
}
